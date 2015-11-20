#!/usr/bin/env ruby

require 'term/ansicolor'
require 'hashdiff'
require 'fileutils'
require 'find'
require 'json'
require 'stringio'
require_relative '../lib/preparermd'

ROOT = File.expand_path('..', File.dirname(__FILE__))
TESTCASE_ROOT = File.join(ROOT, 'test')

include Term::ANSIColor

class Testcase
  attr_reader :outcome, :error, :output
  attr_reader :actual

  def initialize root
    @root = root

    @src = File.join(root, 'src')
    @expected = File.join(root, 'dest')

    @outcome = :pending
    @output = ""
    @diffs = []
    @error = nil

    @actual = File.join(ENV["SCRATCH_DIR"] || Dir.pwd, "preparer-test-#{name}")
  end

  def name
    File.basename @root
  end

  def run
    real_stdout = $stdout
    real_stderr = $stderr
    capture = StringIO.new

    begin
      $stdout = capture
      $stderr = capture

      FileUtils.rm_rf @actual if File.exist? @actual
      FileUtils.mkdir_p @actual
      PreparerMD.build(@src, @actual)

      if self.compare?
        @outcome = :ok
        FileUtils.rm_rf @actual
      else
        @outcome = :fail
      end
    rescue Exception => e
      @outcome = :error
      @error = e
    ensure
      @output = capture.string

      $stdout = real_stdout
      $stderr = real_stderr
    end
  end

  def compare?
    expected_envelopes = envelope_set_from @expected
    expected_assets = asset_set_from @expected

    actual_envelopes = envelope_set_from @actual
    actual_assets = asset_set_from @actual

    HashDiff.diff(actual_envelopes, expected_envelopes).each do |diff|
      op = diff[0]
      key = diff[1]
      rest = diff[2..-1].map { |d| "[#{d}]" }.join(" ")
      @diffs << "#{op} #{bold(key)} #{rest}"
    end

    HashDiff.diff(actual_assets, expected_assets).each do |diff|
      @diffs << diff.join(" ")
    end

    @diffs.empty?
  end

  def envelope_set_from dir
    envelopes = {}
    Find.find(dir) do |path|
      next Find.prune if File.basename(path) == 'assets'

      begin
        doc = JSON.parse(File.read(path))
        envelopes[File.basename(path)] = doc
      rescue
        # No-op
      end
    end
    envelopes
  end

  def asset_set_from dir
    assets = []
    base = File.join(dir, 'assets')

    return assets unless File.exists?(base) && File.directory?(base)

    Find.find(base) do |path|
      assets << path[base.size..-1]
    end
    assets.sort
  end

  def report
    report = StringIO.new
    header, output, diff, stacktrace = false, false, false, false

    case @outcome
    when :fail
      header, diff = true, true
    when :error
      header, output, stacktrace = true, true, true
    end

    if header
      report.puts
      report.puts negative("== Report [#{name}]")
    end

    if output
      report.puts cyan(">> stdout and stderr")
      report.puts @output
    end

    if diff
      report.puts cyan(">> diff")
      report.puts @diffs.join("\n")
    end

    if stacktrace
      report.puts cyan(">> stacktrace")
      report.puts @error
      report.puts @error.backtrace.join("\n  ")
    end

    report.string
  end

  def self.all
    Dir.entries(TESTCASE_ROOT).reject do |e|
      e =~ /^\.\.?$/
    end.map do |e|
      File.join TESTCASE_ROOT, e
    end.select do |p|
      File.directory? p
    end.map do |p|
      new p
    end
  end
end

testcases = Testcase.all

s = testcases.size == 1 ? '' : 's'
puts bold("#{testcases.size} testcase#{s} discovered.")

testcases.each do |testcase|
  print cyan("#{testcase.name} .. ")
  $stdout.flush

  testcase.run

  print case testcase.outcome
    when :ok ; green
    else ; red
    end
  puts testcase.outcome.to_s + reset
end

puts testcases.map { |t| t.report }.join("\n")
