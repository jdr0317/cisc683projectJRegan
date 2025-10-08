# Graph Visualization Project

A comprehensive Ruby implementation of an undirected graph data structure with interactive web-based visualization, developed for CISC 683: Object-Oriented Design.

![Graph Visualization Demo](https://img.shields.io/badge/Ruby-3.0+-red.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## 🎯 Project Overview

This project implements a complete graph library in Ruby featuring:
- Core graph data structure with defensive programming
- Random graph generation with configurable edge probability
- SVG visualization with circular layout
- Depth-first search (DFS) for connected component analysis
- Interactive web interface for real-time graph manipulation

## ✨ Features

### Core Implementation
- **Simple, undirected graphs** - No self-loops or multi-edges
- **Defensive operations** - Invalid inputs return `nil` without mutating state
- **Efficient storage** - Hash-based adjacency lists with Set neighbors
- **Symbol-based nodes** - Clean, Ruby-idiomatic node representation

### Graph Generation
- Generate complete graphs K_n with n nodes
- Probabilistic edge generation (Erdős–Rényi model)
- Deterministic results with seed control
- Configurable graph density

### Visualization
- SVG rendering with circular layouts
- Multi-graph overlay support
- Automatic canvas sizing
- Color-coded component highlighting

### Graph Algorithms
- Depth-first search (DFS)
- Connected component detection
- Subgraph extraction with layout inheritance

## 🚀 Quick Start

### Prerequisites

- Ruby 3.0 or higher
- Bundler (optional)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/graph-project.git
cd graph-project
```

2. Install dependencies:
```bash
gem install victor sinatra
```

3. Run the tests:
```bash
ruby test_graph.rb
```

4. Start the web interface:
```bash
ruby app.rb
```

5. Open your browser to `http://localhost:4567`

## 📁 Project Structure

```
.
├── graph.rb              # Core Graph class implementation
├── graph_utils.rb        # Utility methods (generation, DFS, rendering)
├── test_graph.rb         # Comprehensive test suite
├── app.rb                # Sinatra web application
├── images/               # Generated SVG outputs (created by tests)
└── public/
    └── images/           # Web app SVG outputs (created automatically)
```

## 💻 Usage Examples

### Basic Graph Operations

```ruby
require_relative 'graph'

# Create a new graph
g = Graph.new

# Add nodes
g.add_nodes([:a, :b, :c, :d])

# Add edges
g.add_edge(:a, :b)
g.add_edge(:b, :c)
g.add_edge(:c, :d)

# Query the graph
puts g.nbr_nodes  # => 4
puts g.nbr_edges  # => 3
puts g.to_s       # Adjacency list representation

# Render to SVG
g.render('my_graph.svg', [400, 400], 200)
```

### Generate Random Graphs

```ruby
require_relative 'graph_utils'

# Complete graph with 10 nodes (153 edges)
complete = GraphUtils.genCompleteGraph(10)

# Sparse graph with 20 nodes, 15% edge probability
srand(42)  # For reproducibility
sparse = GraphUtils.genCompleteGraph(20, 0.15)

# Render
sparse.render('sparse_graph.svg', [400, 400], 200)
```

### Depth-First Search

```ruby
require_relative 'graph_utils'

# Generate a sparse graph
srand(42)
g = GraphUtils.genCompleteGraph(24, 0.05)
g.layout_circular([400, 400], 200)

# Find connected component from node :v0
component = GraphUtils.dfs(g, :v0)
puts "Component size: #{component.size}"

# Extract and visualize subgraph
subgraph = GraphUtils.genSubgraph(g, component)

# Render overlay (full graph + highlighted component)
GraphUtils.render_graphs('overlay.svg', [
  [g, 'lightgray', 'white'],
  [subgraph, 'red', 'pink']
])
```

### Custom Graph Building

```ruby
# Build a specific graph structure
g = Graph.new
g.add_nodes([:alice, :bob, :carol, :dave])
g.add_edge(:alice, :bob)
g.add_edge(:bob, :carol)
g.add_edge(:carol, :dave)
g.add_edge(:dave, :alice)

puts g.to_s
# alice -> bob,dave
# bob -> alice,carol
# carol -> bob,dave
# dave -> alice,carol
```

## 🌐 Web Interface

The web application provides two interactive modes:

### Tab 1: Generate Graph (Parts 2-5)
- Configure nodes (3-50) and edge probability (0.0-1.0)
- Generate complete or sparse graphs
- Run DFS from any starting node
- View adjacency list representation
- Real-time visualization

### Tab 2: Build Custom (Part 1)
- Add nodes interactively
- Create edges between nodes
- See operation logs (method calls and return values)
- Demonstrates defensive behavior (rejects invalid operations)
- Visualize custom graphs

## 🧪 Testing

Run the comprehensive test suite:

```bash
ruby test_graph.rb
```

The tests validate:
- ✅ Core graph operations (add_node, add_edge, get_nodes, get_edges)
- ✅ Complete graph generation with various parameters
- ✅ Probabilistic graph generation
- ✅ SVG rendering
- ✅ DFS correctness
- ✅ Subgraph extraction and layout inheritance
- ✅ Multi-graph overlay rendering

Expected output with seed 42:
```
== CISC 683 Graph Project – Tests ==
Images will be written to: ./images/

-- Part 1: Core Graph API --
• add_nodes returns inserted nodes ... OK
• add_edge simple chain a-b, b-c ... OK
• nbr_nodes == 3 ... OK
• nbr_edges == 2 ... OK
...
All tests passed. ✅
```

## 📊 Implementation Details

### Graph Representation
- Adjacency list using Ruby Hash and Set
- Nodes: Symbols (`:v0`, `:v1`, etc.)
- Edges: Stored once as unordered pairs `[u, v]` where `u < v` lexicographically

### Defensive Programming
```ruby
g = Graph.new
g.add_node(:a)

g.add_edge(:a, :b)  # => nil (node :b doesn't exist)
g.add_node(:b)
g.add_edge(:a, :b)  # => [:a, :b] (success)
g.add_edge(:a, :b)  # => nil (duplicate edge)
g.add_edge(:a, :a)  # => nil (self-loop not allowed)
```

### Time Complexity
- `add_node(v)`: O(1)
- `add_edge(u, v)`: O(1)
- `get_nodes`: O(n)
- `get_edges`: O(n + m)
- `nbr_nodes`: O(1)
- `nbr_edges`: O(n)
- `dfs(g, v)`: O(n + m)

### Space Complexity
- Graph storage: O(n + m) where n = nodes, m = edges

## 🎓 Assignment Requirements

This project fulfills all requirements for the CISC 683 Graph Project:

### ✅ Part 1: Core Graph API
- `add_node(node)` - Add single node
- `add_nodes(nodes)` - Add multiple nodes
- `add_edge(u, v)` - Add edge between nodes
- `get_nodes` - Return array of nodes
- `get_edges` - Return array of edges
- `nbr_nodes` - Count nodes
- `nbr_edges` - Count edges
- `to_s` - Adjacency list string representation

### ✅ Part 2: Graph Generation
- `genCompleteGraph(n, p)` - Generate complete/sparse graphs
- Probability parameter `p` controls edge density
- Expected edges: `p × n(n-1)/2`

### ✅ Part 3: Visualization
- `render(filename, center, radius)` - SVG output
- Circular layout with configurable center and radius
- Victor gem for SVG generation

### ✅ Part 4: Depth-First Search
- `dfs(graph, node)` - Find connected components
- Returns array of reachable nodes

### ✅ Part 5: Advanced Rendering
- `render_graphs(filename, graphs_strokes_fills)` - Multi-graph overlay
- `genSubgraph(graph, nodes)` - Extract subgraph
- `inherit_layout_from(parent)` - Layout inheritance

## 🛠️ Technologies Used

- **Ruby 3.0+** - Core language
- **Victor** - SVG generation library
- **Sinatra** - Lightweight web framework
- **Rack** - Web server interface
- **Set** - Efficient neighbor storage

## 📈 Example Outputs

### Complete Graph K₁₀
- Nodes: 10
- Edges: 45
- Every node connected to every other node

### Sparse Graph (n=24, p=0.05)
- Nodes: 24
- Expected edges: ~13.8
- Multiple disconnected components
- Demonstrates probabilistic generation

### DFS Component Visualization
- Gray background: full graph
- Colored overlay: connected component from starting node
- Shows reachability and graph connectivity

## 🤝 Contributing

This is an academic project, but suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

## 📝 License

This project is submitted as coursework for CISC 683: Object-Oriented Design.

For educational and non-commercial use.

## 👤 Author

**Your Name**
- Course: CISC 683 - Object-Oriented Design
- Semester: Fall 2025
- Institution: [Your University]

## 🙏 Acknowledgments

- Assignment designed by CISC 683 course instructor
- Victor gem by Danny Ben Shitrit
- Sinatra web framework by Blake Mizerany

## 📚 Resources

- [Ruby Documentation](https://ruby-doc.org/)
- [Victor SVG Library](https://github.com/DannyBen/victor)
- [Sinatra Documentation](http://sinatrarb.com/)
- [Graph Theory Basics](https://en.wikipedia.org/wiki/Graph_theory)

## 🐛 Known Issues

None currently. If you find a bug, please open an issue!

## 🔮 Future Enhancements

Possible extensions:
- [ ] Directed graph support
- [ ] Weighted edges
- [ ] Additional graph algorithms (BFS, shortest path, minimum spanning tree)
- [ ] Graph export/import (JSON, DOT format)
- [ ] More layout algorithms (force-directed, hierarchical)
- [ ] Graph metrics (diameter, clustering coefficient)

---

**⭐ Star this repository if you find it helpful!**