# CISC 683 – Graph Project (Part 1)
# ------------------------------------------------------------
# Graph class implementing a simple, undirected graph with:
#  - add_node, add_nodes
#  - add_edge (no multi-edges, no self-loops)
#  - get_nodes, get_edges
#  - nbr_nodes, nbr_edges
#  - to_s (adjacency-list string)
#
# Methods are defensive: invalid inputs do not mutate the graph and return nil.
# Nodes are Symbols (e.g., :a, :v0). Edges are unordered pairs stored once.
# ------------------------------------------------------------

require 'set' # to use Set for adjacency lists
require 'victor' # for SVG rendering (optional)

class Graph
	# Initialize an empty graph.
	def initialize
		# @adj maps node(Symbol) -> Set of neighbor nodes(Symbol)
		@adj = Hash.new { |h, k| h[k] = Set.new } # Block initializes empty Set for new keys
	end

	# Add a single node (Symbol). Returns the node if added or already present, else nil.
	def add_node(node)
		return nil unless node.is_a?(Symbol) # valid input
		@adj[node] # ensure key exists; no-op if already present
		node # return the node
	end

	# Add multiple nodes (Array of Symbols). Returns array of nodes added/present.
	def add_nodes(nodes)
		return [] unless nodes.is_a?(Array)
		nodes.map { |n| add_node(n) }.compact
	end

	# Add an undirected edge between two EXISTING nodes. Returns normalized edge [u, v]
	# (with u < v by lexicographic to_s) on success; returns nil for invalid inputs
	# (missing nodes, self-loop, duplicate edge).
	def add_edge(u, v)
		return nil unless u.is_a?(Symbol) && v.is_a?(Symbol)
		return nil unless @adj.key?(u) && @adj.key?(v)
		return nil if u == v # no self-loops, simple graph
		a, b = normalize_edge(u, v) # a < b by to_s
		return nil if @adj[a].include?(b) # duplicate edge, no multi-edges
		@adj[a] << b
		@adj[b] << a
		[a, b]
	end

	# Number of nodes.
	def nbr_nodes
		@adj.size
	end

	# Number of edges (undirected, counted once).
	def nbr_edges
		@adj.values.sum(&:size) / 2
	end

	# Array of nodes (Symbols), in insertion order.
	def get_nodes
		@adj.keys
	end

	# Array of edges as 2-element arrays [u, v] with u < v (by to_s), no duplicates.
	def get_edges
		seen = Set.new
		edges = []
		@adj.each do |u, nbrs|
			nbrs.each do |v|
				a, b = normalize_edge(u, v)
				key = [a, b]
				next if seen.include?(key)
				seen << key
				edges << key
			end
		end
		edges
	end

	# String representation of adjacency lists, lines sorted by node insertion order
	# and neighbors sorted lexicographically by to_s.
	# Example:
	# a -> b
	# b -> a,c
	# c -> b
	def to_s
		get_nodes.map do |u|
			nbrs = @adj[u].to_a.sort_by(&:to_s)
			"%s -> %s" % [u, nbrs.join(',')]
		end.join("\n")
	end

	# Part 5: layout nodes in circular pattern, cache positions in @positions
	# Returns array of nodes in layout order (or [] for invalid inputs or empty graph).
	# center: [x, y] coordinates of circle center (Numeric)
	# radius: radius of circle (positive Numeric)
	# Positions are stored in @positions as node(Symbol) -> [x, y]
	# (coordinates are Float). Repeated calls with same center/radius return
	# cached positions without recomputing.
	# Returns [] for invalid inputs (non-numeric center/radius, non-positive radius).
	# Note: this method does not draw; see render() below.
	def layout_circular(center, radius)
		return [] unless center.is_a?(Array) && center.size == 2 && center.all? { |c| c.is_a?(Numeric) }
		return [] unless radius.is_a?(Numeric) && radius > 0

		cx, cy = center
		nodes = get_nodes
		n = nodes.size
		return nodes if n == 0

		@positions ||= {}
		angle_step = 2.0 * Math::PI / n
		nodes.each_with_index do |node, i|
			angle = i * angle_step
			x = cx + radius * Math.cos(angle)
			y = cy + radius * Math.sin(angle)
			@positions[node] = [x, y]
		end
		nodes
	end

	# Optional: expose positions for Part 5 subgraph inheritance
	def position_of(node)
		@positions && @positions[node]
	end

	def render(filename, center, radius) # Render graph to SVG file using circular layout.
		# Validate inputs
		return nil unless filename.is_a?(String) && !filename.empty?
		return nil unless center.is_a?(Array) && center.size == 2 && center.all? { |c| c.is_a?(Numeric) }
		return nil unless radius.is_a?(Numeric) && radius > 0

		layout_circular(center, radius) # ensure positions are computed (does nothing if already cached)
		return nil if get_nodes.empty? # nothing to render

		# offsets to ensure all nodes fit in SVG with padding
		xs = @positions.values.map { |xy| xy[0] }
		ys = @positions.values.map { |xy| xy[1] }
		pad = 20
		min_x, max_x = xs.min, xs.max
		min_y, max_y = ys.min, ys.max
		width  = ((max_x - min_x) + 2 * pad).ceil
		height = ((max_y - min_y) + 2 * pad).ceil
		offset_x = pad - min_x
		offset_y = pad - min_y

		svg = Victor::SVG.new width: width, height: height # create SVG canvas

		# draw edges
		get_edges.each do |u, v|
			x1, y1 = @positions[u]; x2, y2 = @positions[v]
			svg.line x1: x1 + offset_x, y1: y1 + offset_y,
					x2: x2 + offset_x, y2: y2 + offset_y,
					stroke: 'red', 'stroke-width': 2
		end

		# draw nodes + labels
		node_r = 10
		get_nodes.each do |node|
			x, y = @positions[node]
			svg.circle cx: x + offset_x, cy: y + offset_y, r: node_r,
					fill: 'lightblue', stroke: 'black', 'stroke-width': 2
			svg.text node.to_s, x: x + offset_x, y: y + offset_y + 4,
					'text-anchor': 'middle', 'font-size': 12, fill: 'black'
		end

		File.write(filename, svg.render)
		true
	end

	def inherit_layout_from(parent, nodes = nil)
		nodes ||= get_nodes
		@positions ||= {}
		nodes.each do |n|
			if (pos = parent.position_of(n))
				@positions[n] = pos.dup
			end
		end
		self
	end

	def get_neighbors(node) # Return array of neighbor nodes (Symbols) for given node, or [] if node not present
		return [] unless node.is_a?(Symbol) && @adj.key?(node)
		@adj[node].to_a
	end

	private

	# Normalize edge to canonical ordering [a, b] with a < b by to_s.
	def normalize_edge(u, v)
		[u, v].sort_by(&:to_s)
	end
end
