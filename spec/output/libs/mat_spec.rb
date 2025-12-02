# require 'aruba/rspec'

# RSpec.describe 'Mat Library', type: :aruba do
#   let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

#   describe 'Mathematical constants' do
#     it 'returns correct values for constants' do
#       code = '
#         import("mat")
#         pokazl Mat.PI
#         pokazl Mat.E
#         pokazl Mat.NIESKONCZONOSC
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(Math::PI)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math::E)
#       expect(output_lines[2]).to eq('Infinity')
#     end
#   end

#   describe 'Trigonometric functions' do
#     it 'calculates correct sine values' do
#       code = '
#         import("mat")
#         pokazl Mat.sin(0)
#         pokazl Mat.sin(Mat.PI/2)
#         pokazl Mat.sin(Mat.PI)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(0.0)
#     end

#     it 'calculates correct cosine values' do
#       code = '
#         import("mat")
#         pokazl Mat.cos(0)
#         pokazl Mat.cos(Mat.PI/2)
#         pokazl Mat.cos(Mat.PI)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(-1.0)
#     end

#     it 'calculates correct tangent values' do
#       code = '
#         import("mat")
#         pokazl Mat.tan(0)
#         pokazl Mat.tan(Mat.PI/4)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#     end
#   end

#   describe 'Inverse trigonometric functions' do
#     it 'calculates correct arcsine values' do
#       code = '
#         import("mat")
#         pokazl Mat.asin(0)
#         pokazl Mat.asin(1)
#         pokazl Mat.asin(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math::PI/2)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(-Math::PI/2)
#     end

#     it 'calculates correct arccosine values' do
#       code = '
#         import("mat")
#         pokazl Mat.acos(1)
#         pokazl Mat.acos(0)
#         pokazl Mat.acos(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math::PI/2)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math::PI)
#     end

#     it 'calculates correct arctangent values' do
#       code = '
#         import("mat")
#         pokazl Mat.atan(0)
#         pokazl Mat.atan(1)
#         pokazl Mat.atan(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math::PI/4)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(-Math::PI/4)
#     end

#     it 'calculates correct atan2 values' do
#       code = '
#         import("mat")
#         pokazl Mat.atan2(0, 1)
#         pokazl Mat.atan2(1, 0)
#         pokazl Mat.atan2(-1, 0)
#         pokazl Mat.atan2(0, -1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math::PI/2)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(-Math::PI/2)
#       expect(output_lines[3].to_f).to be_within(0.0001).of(Math::PI)
#     end
#   end

#   describe 'Exponential and logarithmic functions' do
#     it 'calculates correct exponential values' do
#       code = '
#         import("mat")
#         pokazl Mat.exp(0)
#         pokazl Mat.exp(1)
#         pokazl Mat.exp(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math::E)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(1.0 / Math::E)
#     end

#     it 'calculates correct natural logarithm values' do
#       code = '
#         import("mat")
#         pokazl Mat.log(1)
#         pokazl Mat.log(Mat.E)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#     end

#     it 'calculates correct logarithm values with custom base' do
#       code = '
#         import("mat")
#         pokazl Mat.log(16, 2)
#         pokazl Mat.log(100, 10)
#         pokazl Mat.log(125, 5)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(4.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(2.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(3.0)
#     end

#     it 'calculates correct base-10 logarithm values' do
#       code = '
#         import("mat")
#         pokazl Mat.log10(1)
#         pokazl Mat.log10(10)
#         pokazl Mat.log10(100)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(2.0)
#     end

#     it 'calculates correct base-2 logarithm values' do
#       code = '
#         import("mat")
#         pokazl Mat.log2(1)
#         pokazl Mat.log2(2)
#         pokazl Mat.log2(8)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(3.0)
#     end
#   end

#   describe 'Hyperbolic functions' do
#     it 'calculates correct sinh values' do
#       code = '
#         import("mat")
#         pokazl Mat.sinh(0)
#         pokazl Mat.sinh(1)
#         pokazl Mat.sinh(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.sinh(1))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.sinh(-1))
#     end

#     it 'calculates correct cosh values' do
#       code = '
#         import("mat")
#         pokazl Mat.cosh(0)
#         pokazl Mat.cosh(1)
#         pokazl Mat.cosh(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.cosh(1))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.cosh(-1))
#     end

#     it 'calculates correct tanh values' do
#       code = '
#         import("mat")
#         pokazl Mat.tanh(0)
#         pokazl Mat.tanh(1)
#         pokazl Mat.tanh(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.tanh(1))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.tanh(-1))
#     end
#   end

#   describe 'Inverse hyperbolic functions' do
#     it 'calculates correct asinh values' do
#       code = '
#         import("mat")
#         pokazl Mat.asinh(0)
#         pokazl Mat.asinh(1)
#         pokazl Mat.asinh(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.asinh(1))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.asinh(-1))
#     end

#     it 'calculates correct acosh values' do
#       code = '
#         import("mat")
#         pokazl Mat.acosh(1)
#         pokazl Mat.acosh(2)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.acosh(2))
#     end

#     it 'calculates correct atanh values' do
#       code = '
#         import("mat")
#         pokazl Mat.atanh(0)
#         pokazl Mat.atanh(0.5)
#         pokazl Mat.atanh(-0.5)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.atanh(0.5))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.atanh(-0.5))
#     end
#   end

#   describe 'Root functions' do
#     it 'calculates correct square root values' do
#       code = '
#         import("mat")
#         pokazl Mat.sqrt(0)
#         pokazl Mat.sqrt(1)
#         pokazl Mat.sqrt(4)
#         pokazl Mat.sqrt(9)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(2.0)
#       expect(output_lines[3].to_f).to be_within(0.0001).of(3.0)
#     end

#     it 'calculates correct cube root values' do
#       code = '
#         import("mat")
#         pokazl Mat.cbrt(0)
#         pokazl Mat.cbrt(1)
#         pokazl Mat.cbrt(8)
#         pokazl Mat.cbrt(27)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(2.0)
#       expect(output_lines[3].to_f).to be_within(0.0001).of(3.0)
#     end
#   end

#   describe 'Rounding functions' do
#     it 'correctly rounds down' do
#       code = '
#         import("mat")
#         pokazl Mat.floor(1.5)
#         pokazl Mat.floor(2.9)
#         pokazl Mat.floor(-1.5)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(1.0)
#       expect(output_lines[1].to_f).to eq(2.0)
#       expect(output_lines[2].to_f).to eq(-2.0)
#     end

#     it 'correctly rounds up' do
#       code = '
#         import("mat")
#         pokazl Mat.ceil(1.5)
#         pokazl Mat.ceil(2.1)
#         pokazl Mat.ceil(-1.5)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(2.0)
#       expect(output_lines[1].to_f).to eq(3.0)
#       expect(output_lines[2].to_f).to eq(-1.0)
#     end

#     it 'correctly rounds to nearest integer' do
#       code = '
#         import("mat")
#         pokazl Mat.round(1.4)
#         pokazl Mat.round(1.5)
#         pokazl Mat.round(2.9)
#         pokazl Mat.round(-1.5)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(1.0)
#       expect(output_lines[1].to_f).to eq(2.0)
#       expect(output_lines[2].to_f).to eq(3.0)
#       expect(output_lines[3].to_f).to eq(-2.0)
#     end

#     it 'correctly rounds to specified decimal places' do
#       code = '
#         import("mat")
#         pokazl Mat.round(3.14159, 2)
#         pokazl Mat.round(3.14159, 3)
#         pokazl Mat.round(1234.5678, -2)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0]).to eq('3.14')
#       expect(output_lines[1]).to eq('3.142')
#       expect(output_lines[2]).to eq('1200.0')
#     end
#   end

#   describe 'Special functions' do
#     it 'calculates correct gamma function values' do
#       code = '
#         import("mat")
#         pokazl Mat.gamma(1)
#         pokazl Mat.gamma(2)
#         pokazl Mat.gamma(3)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(2.0)
#     end

#     it 'calculates correct lgamma function values' do
#       code = '
#         import("mat")
#         pokazl Mat.lgamma(1)
#         pokazl Mat.lgamma(2)
#         pokazl Mat.lgamma(3)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.log(2.0))
#     end

#     it 'calculates correct error function values' do
#       code = '
#         import("mat")
#         pokazl Mat.erf(0)
#         pokazl Mat.erf(1)
#         pokazl Mat.erf(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(0.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.erf(1))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.erf(-1))
#     end

#     it 'calculates correct complementary error function values' do
#       code = '
#         import("mat")
#         pokazl Mat.erfc(0)
#         pokazl Mat.erfc(1)
#         pokazl Mat.erfc(-1)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to be_within(0.0001).of(1.0)
#       expect(output_lines[1].to_f).to be_within(0.0001).of(Math.erfc(1))
#       expect(output_lines[2].to_f).to be_within(0.0001).of(Math.erfc(-1))
#     end
#   end

#   describe 'Utility functions' do
#     it 'correctly calculates absolute value' do
#       code = '
#         import("mat")
#         pokazl Mat.abs(0)
#         pokazl Mat.abs(5)
#         pokazl Mat.abs(-5)
#         pokazl Mat.abs(-3.14)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(0.0)
#       expect(output_lines[1].to_f).to eq(5.0)
#       expect(output_lines[2].to_f).to eq(5.0)
#       expect(output_lines[3].to_f).to be_within(0.0001).of(3.14)
#     end

#     it 'correctly calculates power' do
#       code = '
#         import("mat")
#         pokazl Mat.potega(2, 3)
#         pokazl Mat.potega(3, 2)
#         pokazl Mat.potega(2, -1)
#         pokazl Mat.potega(4, 0.5)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(8.0)
#       expect(output_lines[1].to_f).to eq(9.0)
#       expect(output_lines[2].to_f).to eq(0.5)
#       expect(output_lines[3].to_f).to eq(2.0)
#     end

#     it 'correctly calculates hypotenuse' do
#       code = '
#         import("mat")
#         pokazl Mat.hipotenuza(3, 4)
#         pokazl Mat.hipotenuza(5, 12)
#         pokazl Mat.hipotenuza(-3, 4)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(5.0)
#       expect(output_lines[1].to_f).to eq(13.0)
#       expect(output_lines[2].to_f).to eq(5.0)
#     end

#     it 'correctly returns minimum of two numbers' do
#       code = '
#         import("mat")
#         pokazl Mat.min(5, 10)
#         pokazl Mat.min(10, 5)
#         pokazl Mat.min(-5, 5)
#         pokazl Mat.min(3.14, 2.71)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(5.0)
#       expect(output_lines[1].to_f).to eq(5.0)
#       expect(output_lines[2].to_f).to eq(-5.0)
#       expect(output_lines[3].to_f).to be_within(0.0001).of(2.71)
#     end

#     it 'correctly returns maximum of two numbers' do
#       code = '
#         import("mat")
#         pokazl Mat.max(5, 10)
#         pokazl Mat.max(10, 5)
#         pokazl Mat.max(-5, 5)
#         pokazl Mat.max(3.14, 2.71)
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       expect(output_lines[0].to_f).to eq(10.0)
#       expect(output_lines[1].to_f).to eq(10.0)
#       expect(output_lines[2].to_f).to eq(5.0)
#       expect(output_lines[3].to_f).to be_within(0.0001).of(3.14)
#     end

#     it 'generates random numbers within specified range' do
#       code = '
#         import("mat")
#         # Test if random numbers are within range
#         dla niech i = 0; 10; 1 {
#           niech random = Mat.losowa_zakres(1, 10)
#           pokazl random >= 1 i random <= 10
#         }
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       # Check if all 10 results are "prawda" (true)
#       expect(output_lines.count { |line| line.strip == "prawda" }).to eq(10)
#     end

#     it 'generates random numbers between 0 and 1' do
#       code = '
#         import("mat")
#         # Test if random numbers are within (0,1) range
#         dla niech i = 0; 10; 1 {
#           niech random = Mat.losowa()
#           pokazl random >= 0 i random < 1
#         }
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       output_lines = last_command_started.output.strip.split("\n")
#       # Check if all 10 results are "prawda" (true)
#       expect(output_lines.count { |line| line.strip == "prawda" }).to eq(10)
#     end
#   end

#   describe 'Error cases' do
#     it 'handles domain errors appropriately' do
#       code = '
#         import("mat")
#         proba {
#           pokazl Mat.sqrt(-1)
#         } zlap (e) {
#           pokazl "Error caught"
#         }
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       expect(last_command_started.output.strip).to eq("Error caught")
#     end

#     it 'handles invalid parameters for logarithm functions' do
#       code = '
#         import("mat")
#         proba {
#           pokazl Mat.log(-1)
#         } zlap (e) {
#           pokazl "Error caught"
#         }
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       expect(last_command_started.output.strip).to eq("Error caught")
#     end

#     it 'handles invalid parameters for inverse trigonometric functions' do
#       code = '
#         import("mat")
#         proba {
#           pokazl Mat.asin(2)
#         } zlap (e) {
#           pokazl "Error caught"
#         }
#       '
#       run_command_and_stop "ruby #{main_file_path} '#{code}'"
#       expect(last_command_started.output.strip).to eq("Error caught")
#     end
#   end
# end
