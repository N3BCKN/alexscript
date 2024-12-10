require 'aruba/rspec'

RSpec.describe 'Cli', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  it 'evaluates number primary expression' do
    run_command_and_stop "ruby #{main_file_path} '7.7'"
    expected_output = [
      'type_number',
      '7.7'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates boolean primary expression' do
    run_command_and_stop "ruby #{main_file_path} 'prawda'"
    expected_output = %w[
      type_bool
      prawda
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates addition' do
    run_command_and_stop "ruby #{main_file_path} '2 + 2'"
    expected_output = [
      'type_number',
      '4.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates multiplication' do
    run_command_and_stop "ruby #{main_file_path} '2 * 9'"
    expected_output = [
      'type_number',
      '18.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates division' do
    run_command_and_stop "ruby #{main_file_path} '9 / 2'"
    expected_output = [
      'type_number',
      '4.5'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates operator precedence' do
    run_command_and_stop "ruby #{main_file_path} '2 * 9 + 13'"
    expected_output = [
      'type_number',
      '31.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates unary minus' do
    run_command_and_stop "ruby #{main_file_path} '2 * 9 - -5'"
    expected_output = [
      'type_number',
      '23.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates power operator' do
    run_command_and_stop "ruby #{main_file_path} '2^3^3 - 1'"
    expected_output = [
      'type_number',
      '134217727.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates modulo operator' do
    run_command_and_stop "ruby #{main_file_path} '(2^3^3-1) % 2'"
    expected_output = [
      'type_number',
      '1.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates parentheses expression 1' do
    run_command_and_stop "ruby #{main_file_path} '2 * (9 + 13) / 2'"
    expected_output = [
      'type_number',
      '22.0'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates complex parentheses expression 2' do
    run_command_and_stop "ruby #{main_file_path} '2 * (9 + 13) + 2^2 + (((3 * 3) - 3) + 3.324) / 2.1'"
    expected_output = [
      'type_number',
      '52.44'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates nested division with parentheses' do
    run_command_and_stop "ruby #{main_file_path} '14 / (12 / 2) / 2'"
    expected_output = [
      'type_number',
      '1.1666666666666667'
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates boolean OR operation' do
    run_command_and_stop "ruby #{main_file_path} 'prawda lub falsz'"
    expected_output = %w[
      type_bool
      prawda
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates complex boolean expression with OR and AND' do
    run_command_and_stop "ruby #{main_file_path} '(44 >= 2) lub falsz i 1 > 0'"
    expected_output = %w[
      type_bool
      true
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates NOT operation' do
    run_command_and_stop "ruby #{main_file_path} '!(44 >= 2)'"
    expected_output = %w[
      type_bool
      false
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates NOT EQUAL operation' do
    run_command_and_stop "ruby #{main_file_path} '!(3 != 2)'"
    expected_output = %w[
      type_bool
      false
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end

  it 'evaluates EQUAL operation' do
    run_command_and_stop "ruby #{main_file_path} '(3 == 2 + 1)'"
    expected_output = %w[
      type_bool
      true
    ].join("\n")

    expect(last_command_started.output.strip).to eq(expected_output)
  end
end
