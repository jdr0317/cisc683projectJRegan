#!/usr/bin/env ruby
# CISC 683 — Graph Project Test Runner
# Usage:
#   ruby test_graph.rb
#
# Generates SVGs in ./images and prints concise pass/fail output.

require 'fileutils'
require_relative 'graph'
require_relative 'graph_utils'

# -----------------------
# Tiny assertion helpers
# -----------------------
class Test
	def self.assert(name, &blk)
	  print "• #{name} ... "
	  result = blk.call
	  if result
	    puts "OK"
	  else
	    puts "FAIL"
	    exit(1)
	  end
	end

	def self.eq(a, b)
	  a == b
	end

	def self.between(x, lo, hi)
	  x >= lo && x <= hi
	end
end

# Ensure images directory exists
IMAGES_DIR = File.join(__dir__, 'images/')
FileUtils.mkdir_p(IMAGES_DIR)

puts "== CISC 683 Graph Project — Tests =="
puts "Images will be written to: #{IMAGES_DIR}"
puts

# -----------------------
# Part 1: Core graph API
# -----------------------
puts "-- Part 1: Core Graph API --"

g = Graph.new
Test.assert("add_nodes returns inserted nodes") do
	added = g.add_nodes(%i[a b c])
	Test.eq(added, %i[a b c])
end

Test.assert("add_edge simple chain a-b, b-c (no self/dupe)") do
	e1 = g.add_edge(:a, :b)
	e2 = g.add_edge(:b, :c)
	e3 = g.add_edge(:b, :b) # self-loop rejected
	e4 = g.add_edge(:a, :b) # duplicate rejected
	e1 && e2 && e3.nil? && e4.nil?
end

Test.assert("nbr_nodes == 3") { Test.eq(g.nbr_nodes, 3) }
Test.assert("nbr_edges == 2") { Test.eq(g.nbr_edges, 2) }

Test.assert("get_edges canonical form") do
	edges = g.get_edges
	# Should be [[a,b],[b,c]] in some order, but canonical pairs u<v by to_s
	edges.sort == [[:a, :b], [:b, :c]]
end

Test.assert("to_s adjacency list formatting (neighbors sorted by to_s)") do
	s = g.to_s
	# Expected:
	# a -> b
	# b -> a,c
	# c -> b
	lines = s.split("\n")
	lines.size == 3 &&
	  lines[0] == "a -> b" &&
	  lines[1] == "b -> a,c" &&
	  lines[2] == "c -> b"
end

# -----------------------------------------
# Part 2: genCompleteGraph(n, p) examples
# -----------------------------------------
puts "\n-- Part 2: genCompleteGraph --"

Test.assert("complete graph c18 has 18 nodes, 153 edges") do
	c18 = GraphUtils.genCompleteGraph(18, 1.0)
	c18.nbr_nodes == 18 && c18.nbr_edges == (18 * 17 / 2)
end

Test.assert("probabilistic graph c24 with p=0.05 has edges in a reasonable range") do
	srand(42) # determinism if you want identical results per run
	c24 = GraphUtils.genCompleteGraph(24, 0.05)
	# Expected edges ~ p * n*(n-1)/2 = 0.05 * 276 ≈ 13.8
	# Accept a small range to avoid brittle tests
	Test.between(c24.nbr_edges, 8, 22)
end

# ----------------------------------------------------
# Part 3: render() using circular layout to an SVG
# ----------------------------------------------------
puts "\n-- Part 3: render() to SVG --"

c18 = GraphUtils.genCompleteGraph(18, 1.0)
out1 = File.join(IMAGES_DIR, 'c18.svg')
Test.assert("c18 render to images/c18.svg returns true") do
	c18.render(out1, [400, 400], 200) == true && File.exist?(out1)
end

# ----------------------------------------------------
# Part 4: DFS (connected component listing)
# ----------------------------------------------------
puts "\n-- Part 4: DFS --"

Test.assert("dfs on c18 (complete) from :v0 visits all 18 nodes") do
	nodes = GraphUtils.dfs(c18, :v0)
	nodes.is_a?(Array) && nodes.size == 18 && nodes.all? { |x| x.is_a?(Symbol) }
end

# ----------------------------------------------------
# Part 5: Layout, subgraph inheritance, overlaid render
# ----------------------------------------------------
puts "\n-- Part 5: Layout + Subgraph + Multi-graph render --"

# Build a sparse c24 (p ~ 0.05), lay it out, take a component from :v0,
# then render overlay of (full graph, component) with different colors.
srand(42)
c24 = GraphUtils.genCompleteGraph(24, 0.05)

Test.assert("layout_circular on c24 caches positions") do
	order = c24.layout_circular([400, 400], 200)
    # Render the full sparse c24 graph before overlay, just like the assignment example
    c24_file = File.join(IMAGES_DIR, 'c24.svg')
    Test.assert("render full sparse c24 graph to images/c24.svg") do
        c24.render(c24_file, [400, 400], 200) == true && File.exist?(c24_file)
end

	ok = order.is_a?(Array) && order.size == c24.nbr_nodes
	ok && c24.get_nodes.all? { |n| c24.position_of(n).is_a?(Array) }
end

ns = GraphUtils.dfs(c24, :v0)
Test.assert("dfs on c24 from :v0 yields non-empty component") do
	ns.is_a?(Array) && ns.size >= 1
end

c24v0 = GraphUtils.genSubgraph(c24, ns)
Test.assert("subgraph inherits parent positions for overlapping nodes") do
	ns.all? { |n| c24v0.position_of(n) == c24.position_of(n) }
end

overlay = File.join(IMAGES_DIR, 'c24_overlay.svg')
Test.assert("render_graphs overlay (full green/blue, component red/red)") do
	GraphUtils.render_graphs(overlay, [[c24, 'green', 'blue'], [c24v0, 'red', 'red']]) &&
	  File.exist?(overlay)
end

# Also render the component alone (like the assignment example)
comp_only = File.join(IMAGES_DIR, 'c24v0.svg')
Test.assert("render component alone to images/c24v0.svg") do
	c24v0.render(comp_only, [400, 400], 200) == true && File.exist?(comp_only)
end

Test.assert("Expected number of edges in c24 (~13.8 ± 11.8 @99.9%)") do
    puts "nodes=#{c24.nbr_nodes}, edges=#{c24.nbr_edges}"
    expected = 13.8
    stddev   = 3.6
    lower    = expected - 3.29 * stddev
    upper    = expected + 3.29 * stddev

    # Check if within 99.9% confidence interval
    c24.nbr_edges.between?(lower, upper)
end


puts "\nAll tests passed. ✅"
puts "Open the generated SVGs:"
puts "  - #{out1}"
puts "  - #{overlay}"
puts "  - #{comp_only}"
	      