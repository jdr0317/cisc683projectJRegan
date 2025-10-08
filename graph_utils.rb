# CISC 683 – Graph Project (Part 2)
# ------------------------------------------------------------
# GraphUtils.genCompleteGraph(n, p = 1.0)
#  - Builds a graph with nodes :v0..:v{n-1}
#  - For every unordered pair, adds an edge with probability p
#  - p = 1.0 yields a complete graph with n*(n-1)/2 edges
#  - p = 0.0 yields n isolated nodes
#  - Determinism: pass srand(seed) before calling if you want repeatable graphs
# ------------------------------------------------------------

require 'set'
require_relative 'graph'

class GraphUtils
	class << self
		# Generate a (possibly) complete graph on n nodes with edge probability p in [0.0, 1.0].
		# Nodes are named :v0, :v1, ..., :v{n-1}.
		# Raises ArgumentError for invalid inputs.
		def genCompleteGraph(n, p = 1.0)
			validate_gen_args!(n, p)

			g = Graph.new
			nodes = Array.new(n) { |i| ("v#{i}").to_sym }
			g.add_nodes(nodes)

			# Iterate all unordered pairs and add with probability p for each edge (expected edges = p * n*(n-1)/2)
			nodes.combination(2) do |u, v|
				if p == 1.0 || (p > 0.0 && rand < p)
					g.add_edge(u, v)
				end
			end

		  g
		end

		def dfs(graph, start_node, &block)
			return [] unless start_node.is_a?(Symbol)
			return [] unless graph.get_nodes.include?(start_node)

			visited = Set.new
			rec = nil
			rec = ->(node) do
				return if visited.include?(node)
				visited << node
				block&.call(node)
				graph.get_neighbors(node).each { |nbr| rec.call(nbr) }
			end

			rec.call(start_node)
			visited.to_a
		end

		def genSubgraph(graph, nodes)
			nodes = nodes.to_a
			sub = Graph.new
			sub.add_nodes(nodes)

			need = nodes.to_set
			graph.get_edges.each do |u, v|
				sub.add_edge(u, v) if need.include?(u) && need.include?(v)
			end

			sub.inherit_layout_from(graph, nodes)
		end


		def render_graphs(filename, graphs_strokes_fills)
			raise ArgumentError, 'filename required' unless filename.is_a?(String) && !filename.empty?
			raise ArgumentError, 'graphs_strokes_fills must be an Array' unless graphs_strokes_fills.is_a?(Array)
			raise 'Victor gem not available' unless defined?(Victor)

			# Collect positioned points to size canvas
			points = []
			graphs_strokes_fills.each do |g, _stroke, _fill|
				g.get_nodes.each do |n|
					if (pos = g.position_of(n))
						points << pos
					end
				end
			end
			return false if points.empty?

			min_x = points.map { |p| p[0] }.min
			max_x = points.map { |p| p[0] }.max
			min_y = points.map { |p| p[1] }.min
			max_y = points.map { |p| p[1] }.max

			pad = 20
			width  = ((max_x - min_x) + 2 * pad).ceil
			height = ((max_y - min_y) + 2 * pad).ceil
			offset_x = pad - min_x
			offset_y = pad - min_y

			svg = Victor::SVG.new width: width, height: height

			graphs_strokes_fills.each do |g, scolor, fcolor|
				# Edges
				g.get_edges.each do |u, v|
					x1, y1 = g.position_of(u); x2, y2 = g.position_of(v)
					next unless x1 && y1 && x2 && y2
					svg.line x1: x1 + offset_x, y1: y1 + offset_y,
					         x2: x2 + offset_x, y2: y2 + offset_y,
					         stroke: scolor, 'stroke-width': 1
				end
				# Nodes + labels
				g.get_nodes.each do |node|
					x, y = g.position_of(node)
					next unless x && y
					svg.circle cx: x + offset_x, cy: y + offset_y, r: 12,
					           fill: fcolor, stroke: scolor, 'stroke-width': 1
					svg.text node.to_s, x: x + offset_x, y: y + offset_y + 4,
					         'text-anchor': 'middle', 'font-size': 12, fill: 'black'
				end
			end

			File.write(filename, svg.render)
			true
		end

		private

		def validate_gen_args!(n, p) # Raise ArgumentError for invalid n or p
			# n must be positive Integer, p in [0.0, 1.0]
			unless n.is_a?(Integer) && n > 0
				raise ArgumentError, "n must be a positive Integer; got #{n.inspect}"
			end
			unless p.is_a?(Numeric) && p >= 0.0 && p <= 1.0
				raise ArgumentError, "p must be in [0.0, 1.0]; got #{p.inspect}"
			end
		end
	end
end

# ------------------------
# Quick demo (optional)
# ------------------------
if __FILE__ == $0
	# Deterministic run
	srand(42)
	g = GraphUtils.genCompleteGraph(5, 0.5)
	puts "nodes=#{g.nbr_nodes}, edges=#{g.nbr_edges}"
	puts g
end
