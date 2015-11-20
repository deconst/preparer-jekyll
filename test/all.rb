#!/usr/bin/env ruby

require 'hashdiff'
require 'fileutils'
require 'find'
require 'set'
require 'json'
require 'stringio'
require_relative '../lib/preparermd'

ROOT = File.expand_path('..', File.dirname(__FILE__))
TESTCASE_ROOT = File.join(ROOT, 'test')

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

      FileUtils.mkdir_p @actual
      PreparerMD.build(@root, @actual)

      if self.compare?
        @outcome = :ok
        FileUtil.rm_rf @actual
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

    actual_envelopes = envelope_set_from(@actual).to_a.sort
    actual_assets = asset_set_from(@actual).to_a.sort

    HashDiff.diff(actual_envelopes, expected_envelopes).each do |diff|
      @diffs << diff.join(" ")
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
    assets = Set.new
    base = File.join(dir, 'assets')
    Find.find(base) do |path|
      assets.add(path[base.size..-1])
    end
    assets
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
puts "#{testcases.size} testcase#{s} discovered."

testcases.each do |testcase|
  print "#{testcase.name} .. "
  $stdout.flush

  testcase.run

  puts testcase.outcome
end
