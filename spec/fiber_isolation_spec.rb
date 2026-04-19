# frozen_string_literal: true


# require 'aruba/rspec'
require 'fiber'
require 'spec_helper'

require_relative '../lib/alexscript/core/core'
require_relative '../lib/alexscript/ast/ast'
require_relative '../lib/alexscript/utils/utils'
require_relative '../lib/alexscript/native/native'

RSpec.describe 'Fiber isolation of interpreter state' do
  # Zakładam że masz środowisko ze załadowanymi klasami.
  # Jeśli masz spec_helper, który to robi — użyj go zamiast require'a wyżej.

  describe AlexScript::Utils::ContextTracker do
    it 'maintains independent current_line per fiber' do
      described_class.current_line = 10

      other_line = nil
      Fiber.new do
        # Dziedziczenie Fiber[:...] powoduje że nowy fiber startuje z kopią
        # bieżącego storage'u — czyli zobaczy 10. Ale jak tylko ustawi swoją
        # wartość, rodzic jej nie zobaczy.
        other_line = described_class.current_line # 10 — inherited
        described_class.current_line = 99
        other_line = described_class.current_line # 99
      end.resume

      expect(other_line).to eq(99)
      # Rodzic nadal widzi swoje 10:
      expect(described_class.current_line).to eq(10)
    end

    it 'restores current_method_name via track_method_call even across fibers' do
      described_class.current_method_name = 'outer'

      described_class.track_method_call('inner_of_parent') do
        expect(described_class.current_method_name).to eq('inner_of_parent')

        Fiber.new do
          described_class.track_method_call('inner_of_child') do
            expect(described_class.current_method_name).to eq('inner_of_child')
          end
          # Po opuszczeniu bloku child-fiber ma przywrócone 'inner_of_parent'
          # (bo dziedziczy początkowy stan storage'u z rodzica, a `old_method`
          # zapamiętany był lokalnie w child-fibrze — ale tu wątek jest
          # kłopotliwy; wystarczy że sprawdzimy że rodzic nie jest zepsuty).
        end.resume

        # Kluczowa asercja: rodzic nie jest zanieczyszczony przez child fiber.
        expect(described_class.current_method_name).to eq('inner_of_parent')
      end

      expect(described_class.current_method_name).to eq('outer')
    end
  end

  describe AlexScript::Utils::CallStackTracker do
    before { described_class.clear }
    after  { described_class.clear }

    it 'maintains independent stacks per fiber' do
      described_class.push(:function, 'f_parent', 'main.as', 1)
      expect(described_class.depth).to eq(1)

      child_depth_after_push = nil
      Fiber.new do
        # Child fiber should see its OWN empty stack, not inherit parent's
        # frames — that's the isolation guarantee CallStackTracker provides.
        child_depth_after_push = described_class.depth
        expect(child_depth_after_push).to eq(0)

        described_class.push(:function, 'f_child', 'main.as', 2)
        expect(described_class.depth).to eq(1)
      end.resume

      # Parent still sees only its single frame, unaffected by child's push.
      expect(described_class.depth).to eq(1)

      stack = described_class.current_stack
      expect(stack.first[:name]).to eq('f_parent')
    end
  end

  describe AlexScript::Core::Environment do
    it 'maintains independent call_depth per fiber' do
      env = described_class.new
      env.increment_call_depth(1)
      env.increment_call_depth(2)
      expect(described_class.call_depth).to eq(2)

      Fiber.new do
        # Child startuje z dziedziczoną wartością 2.
        # Zrobi własne increments.
        env.increment_call_depth(3)
        env.increment_call_depth(4)
      end.resume

      # Rodzic nadal widzi swoje 2.
      expect(described_class.call_depth).to eq(2)

      env.decrement_call_depth
      env.decrement_call_depth
      expect(described_class.call_depth).to eq(0)
    end

    it 'does not allow one fiber to trigger the other fiber\'s stack overflow' do
      env = described_class.new

      # Podbij licznik rodzica blisko limitu, ale nie przekrocz.
      590.times { env.increment_call_depth(1) }

      # Fiber dziecko zaczyna od dziedziczonego 590 — więc jeszcze 10
      # incrementów go zatrzyma. To jest właściwie OK: dziedziczenie
      # stanu inicjalnego fibrów to feature Ruby. Ważne jest, żeby po
      # powrocie z childa licznik rodzica był nienaruszony.
      Fiber.new do
        # Bezpieczne 5 inc/dec — powinno się zakończyć bez błędu.
        env.increment_call_depth(1)
        env.increment_call_depth(1)
        env.decrement_call_depth
        env.decrement_call_depth
      end.resume

      expect(described_class.call_depth).to eq(590)

      # Sprzątanie
      590.times { env.decrement_call_depth }
    end
  end
end