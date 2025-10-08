#!/usr/bin/env ruby
# Graph Visualization Web Application
# Usage: ruby app.rb
# Then open http://localhost:4567 in your browser

require 'sinatra'
require 'json'
require 'fileutils'
require_relative 'graph'
require_relative 'graph_utils'

# Enable sessions for custom graph storage
enable :sessions
set :session_secret, 'cisc683_graph_project_secret_key_that_is_at_least_64_bytes_long_for_security'

# Ensure public directory exists for serving SVGs
PUBLIC_DIR = File.join(__dir__, 'public')
IMAGES_DIR = File.join(PUBLIC_DIR, 'images')
FileUtils.mkdir_p(IMAGES_DIR)

set :public_folder, PUBLIC_DIR
set :port, 4567

# Global storage for custom graphs
$custom_graphs = {}

# Home page with controls
get '/' do
  erb :index
end

# Generate a complete graph
post '/generate' do
  content_type :json
  
  begin
    n = params[:nodes].to_i
    p = params[:probability].to_f
    seed = params[:seed].to_i
    
    # Validate inputs
    return { error: "Nodes must be between 3 and 50" }.to_json if n < 3 || n > 50
    return { error: "Probability must be between 0.0 and 1.0" }.to_json if p < 0.0 || p > 1.0
    
    # Generate graph with deterministic seed
    srand(seed) if seed > 0
    graph = GraphUtils.genCompleteGraph(n, p)
    
    # Render graph
    filename = "graph_#{Time.now.to_i}.svg"
    filepath = File.join(IMAGES_DIR, filename)
    graph.render(filepath, [400, 400], 200)
    
    {
      success: true,
      nodes: graph.nbr_nodes,
      edges: graph.nbr_edges,
      expected_edges: (n * (n - 1) / 2.0 * p).round(1),
      image_url: "/images/#{filename}",
      graph_data: {
        nodes: graph.get_nodes.map(&:to_s),
        edges: graph.get_edges.map { |u, v| [u.to_s, v.to_s] }
      }
    }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

# Run DFS and visualize connected component
post '/dfs' do
  content_type :json
  
  begin
    n = params[:nodes].to_i
    p = params[:probability].to_f
    seed = params[:seed].to_i
    start_node = params[:start_node]
    
    # Regenerate same graph
    srand(seed) if seed > 0
    graph = GraphUtils.genCompleteGraph(n, p)
    graph.layout_circular([400, 400], 200)
    
    # Run DFS
    start_sym = start_node.to_sym
    component_nodes = GraphUtils.dfs(graph, start_sym)
    
    # Create subgraph
    subgraph = GraphUtils.genSubgraph(graph, component_nodes)
    
    # Render overlay
    filename = "dfs_#{Time.now.to_i}.svg"
    filepath = File.join(IMAGES_DIR, filename)
    GraphUtils.render_graphs(filepath, [
      [graph, 'lightgray', 'white'],
      [subgraph, 'red', 'pink']
    ])
    
    {
      success: true,
      component_size: component_nodes.size,
      component_nodes: component_nodes.map(&:to_s),
      component_edges: subgraph.nbr_edges,
      image_url: "/images/#{filename}"
    }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

# Get adjacency list representation
post '/adjacency' do
  content_type :json
  
  begin
    n = params[:nodes].to_i
    p = params[:probability].to_f
    seed = params[:seed].to_i
    
    srand(seed) if seed > 0
    graph = GraphUtils.genCompleteGraph(n, p)
    
    {
      success: true,
      adjacency_list: graph.to_s
    }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

# Custom graph builder - demonstrates Part 1 API
post '/custom/create' do
  content_type :json
  
  begin
    graph = Graph.new
    session_id = "custom_#{Time.now.to_i}_#{rand(1000)}"
    
    $custom_graphs[session_id] = graph
    
    {
      success: true,
      session_id: session_id,
      nodes: 0,
      edges: 0
    }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

post '/custom/add_node' do
  content_type :json
  
  begin
    session_id = params[:session_id]
    node_name = params[:node_name].strip
    
    return { error: "Invalid session" }.to_json unless $custom_graphs&.key?(session_id)
    
    graph = $custom_graphs[session_id]
    node_sym = node_name.to_sym
    
    result = graph.add_node(node_sym)
    
    if result
      {
        success: true,
        message: "Added node :#{node_name}",
        nodes: graph.nbr_nodes,
        edges: graph.nbr_edges,
        adjacency_list: graph.to_s
      }.to_json
    else
      { error: "Could not add node (must be a valid symbol)" }.to_json
    end
  rescue => e
    { error: e.message }.to_json
  end
end

post '/custom/add_edge' do
  content_type :json
  
  begin
    session_id = params[:session_id]
    node1 = params[:node1].strip
    node2 = params[:node2].strip
    
    return { error: "Invalid session" }.to_json unless $custom_graphs&.key?(session_id)
    
    graph = $custom_graphs[session_id]
    result = graph.add_edge(node1.to_sym, node2.to_sym)
    
    if result
      {
        success: true,
        message: "Added edge #{node1}--#{node2}",
        nodes: graph.nbr_nodes,
        edges: graph.nbr_edges,
        adjacency_list: graph.to_s
      }.to_json
    else
      { 
        error: "Could not add edge (check: both nodes exist, not a duplicate, not a self-loop)" 
      }.to_json
    end
  rescue => e
    { error: e.message }.to_json
  end
end

post '/custom/render' do
  content_type :json
  
  begin
    session_id = params[:session_id]
    
    return { error: "Invalid session" }.to_json unless $custom_graphs&.key?(session_id)
    
    graph = $custom_graphs[session_id]
    
    return { error: "Graph is empty" }.to_json if graph.nbr_nodes == 0
    
    filename = "custom_#{Time.now.to_i}.svg"
    filepath = File.join(IMAGES_DIR, filename)
    graph.render(filepath, [400, 400], 200)
    
    {
      success: true,
      image_url: "/images/#{filename}",
      nodes: graph.nbr_nodes,
      edges: graph.nbr_edges
    }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

post '/custom/adjacency' do
  content_type :json
  
  begin
    session_id = params[:session_id]
    
    return { error: "Invalid session" }.to_json unless $custom_graphs&.key?(session_id)
    
    graph = $custom_graphs[session_id]
    
    {
      success: true,
      adjacency_list: graph.to_s,
      nodes_list: graph.get_nodes.map(&:to_s).join(', '),
      edges_list: graph.get_edges.map { |u, v| "[#{u}, #{v}]" }.join(', ')
    }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

__END__

@@index
<!DOCTYPE html>
<html>
<head>
  <title>Graph Visualization Demo - CISC 683</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 20px;
    }
    .container {
      max-width: 1400px;
      margin: 0 auto;
      background: white;
      border-radius: 12px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      overflow: hidden;
    }
    header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      text-align: center;
    }
    h1 { font-size: 2.5em; margin-bottom: 10px; }
    .subtitle { opacity: 0.9; font-size: 1.1em; }
    .tabs {
      display: flex;
      background: #e9ecef;
      border-bottom: 2px solid #dee2e6;
    }
    .tab {
      flex: 1;
      padding: 15px;
      background: #e9ecef;
      border: none;
      cursor: pointer;
      font-weight: 600;
      transition: all 0.3s;
      border-right: 1px solid #dee2e6;
    }
    .tab:hover { background: #dee2e6; }
    .tab.active {
      background: #f8f9fa;
      color: #667eea;
      border-bottom: 3px solid #667eea;
      margin-bottom: -2px;
    }
    .content {
      display: grid;
      grid-template-columns: 350px 1fr;
      gap: 0;
      min-height: 600px;
    }
    .tab-content { display: none; }
    .tab-content.active { display: contents; }
    .sidebar {
      background: #f8f9fa;
      padding: 30px;
      border-right: 1px solid #dee2e6;
    }
    .control-group { margin-bottom: 25px; }
    label {
      display: block;
      font-weight: 600;
      margin-bottom: 8px;
      color: #495057;
    }
    input[type="number"], input[type="text"] {
      width: 100%;
      padding: 10px;
      border: 2px solid #dee2e6;
      border-radius: 6px;
      font-size: 14px;
      transition: border-color 0.2s;
    }
    input:focus {
      outline: none;
      border-color: #667eea;
    }
    .range-container {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    input[type="range"] { flex: 1; }
    .range-value {
      min-width: 45px;
      font-weight: 600;
      color: #667eea;
    }
    button {
      width: 100%;
      padding: 12px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      border-radius: 6px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: transform 0.2s, box-shadow 0.2s;
      margin-bottom: 10px;
    }
    button:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
    }
    button:active { transform: translateY(0); }
    button.secondary {
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    }
    button.tertiary {
      background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    }
    .main-content {
      padding: 30px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
    }
    .stat-card {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
    }
    .stat-value {
      font-size: 2em;
      font-weight: bold;
      margin-bottom: 5px;
    }
    .stat-label {
      opacity: 0.9;
      font-size: 0.9em;
    }
    .visualization {
      background: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
      min-height: 400px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 2px dashed #dee2e6;
    }
    .visualization img {
      max-width: 100%;
      height: auto;
      border-radius: 4px;
    }
    .placeholder {
      text-align: center;
      color: #6c757d;
    }
    .placeholder-icon {
      font-size: 4em;
      margin-bottom: 10px;
    }
    .error {
      background: #f8d7da;
      color: #721c24;
      padding: 15px;
      border-radius: 6px;
      border: 1px solid #f5c6cb;
    }
    .adjacency-output {
      background: #f8f9fa;
      border: 1px solid #dee2e6;
      border-radius: 6px;
      padding: 15px;
      font-family: 'Courier New', monospace;
      font-size: 13px;
      max-height: 300px;
      overflow-y: auto;
      white-space: pre-wrap;
    }
    .info-text {
      font-size: 0.85em;
      color: #6c757d;
      margin-top: 5px;
    }
    .loading {
      display: none;
      text-align: center;
      padding: 20px;
      color: #667eea;
    }
    .loading.active { display: block; }
    .node-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin: 15px 0;
      padding: 10px;
      background: #f8f9fa;
      border-radius: 6px;
      min-height: 40px;
    }
    .node-badge {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 5px 12px;
      border-radius: 15px;
      font-size: 13px;
      font-weight: 600;
    }
    .input-group {
      display: flex;
      gap: 8px;
      margin-bottom: 15px;
    }
    .input-group input { flex: 1; }
    .input-group button {
      width: auto;
      padding: 10px 20px;
      margin: 0;
    }
    .operation-log {
      background: #f8f9fa;
      border: 1px solid #dee2e6;
      border-radius: 6px;
      padding: 10px;
      max-height: 150px;
      overflow-y: auto;
      font-family: 'Courier New', monospace;
      font-size: 12px;
      margin-bottom: 15px;
    }
    .operation-log .op-success { color: #28a745; }
    .operation-log .op-error { color: #dc3545; }
    small.helper {
      display: block;
      color: #6c757d;
      font-size: 0.85em;
      margin-top: 5px;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>🕸️ Graph Visualization Demo</h1>
      <div class="subtitle">CISC 683 Object-Oriented Design Project</div>
    </header>
    
    <div class="tabs">
      <button class="tab active" onclick="switchTab('generate')">Generate Graph (Parts 2-5)</button>
      <button class="tab" onclick="switchTab('custom')">Build Custom (Part 1)</button>
    </div>
    
    <div class="content">
      <!-- GENERATE TAB -->
      <div id="tab-generate" class="tab-content active">
        <div class="sidebar">
          <div class="control-group">
            <label>Number of Nodes (n)</label>
            <input type="number" id="nodes" value="18" min="3" max="50">
            <div class="info-text">3 to 50 nodes</div>
          </div>
          
          <div class="control-group">
            <label>Edge Probability (p)</label>
            <div class="range-container">
              <input type="range" id="probability" value="1.0" min="0" max="1" step="0.05">
              <span class="range-value" id="prob-value">1.00</span>
            </div>
            <div class="info-text">0.0 = no edges, 1.0 = complete graph</div>
          </div>
          
          <div class="control-group">
            <label>Random Seed</label>
            <input type="number" id="seed" value="42" min="0">
            <div class="info-text">Use same seed for reproducibility</div>
          </div>
          
          <button onclick="generateGraph()">Generate Graph</button>
          
          <div class="control-group" style="margin-top: 30px;">
            <label>Start Node for DFS</label>
            <input type="text" id="start-node" value="v0" placeholder="e.g., v0">
            <div class="info-text">Run depth-first search</div>
          </div>
          
          <button class="secondary" onclick="runDFS()">Run DFS</button>
          <button class="tertiary" onclick="showAdjacency()">Show Adjacency List</button>
        </div>

        <div class="main-content">
          <div id="error-message" style="display:none;" class="error"></div>
          
          <div class="stats" id="stats" style="display:none;">
            <div class="stat-card">
              <div class="stat-value" id="stat-nodes">0</div>
              <div class="stat-label">Nodes</div>
            </div>
            <div class="stat-card">
              <div class="stat-value" id="stat-edges">0</div>
              <div class="stat-label">Edges</div>
            </div>
            <div class="stat-card">
              <div class="stat-value" id="stat-expected">0</div>
              <div class="stat-label">Expected Edges</div>
            </div>
          </div>
          
          <div class="visualization" id="visualization">
            <div class="placeholder">
              <div class="placeholder-icon">📊</div>
              <div>Generate a graph to visualize it here</div>
            </div>
          </div>
          
          <div class="loading" id="loading">
            <div>⏳ Processing...</div>
          </div>
          
          <div id="adjacency-container" style="display:none;">
            <h3>Adjacency List Representation</h3>
            <div class="adjacency-output" id="adjacency-output"></div>
          </div>
        </div>
      </div>

      <!-- CUSTOM BUILDER TAB -->
      <div id="tab-custom" class="tab-content">
        <div class="sidebar">
          <h3 style="margin-bottom: 20px;">Part 1: Core Graph API</h3>
          
          <div class="control-group">
            <label>Add Node</label>
            <div class="input-group">
              <input type="text" id="custom-node" placeholder="e.g., a, b, c">
              <button onclick="addCustomNode()">Add</button>
            </div>
            <small class="helper">Nodes must be valid symbols (letters/numbers)</small>
          </div>
          
          <div class="control-group">
            <label>Current Nodes</label>
            <div class="node-list" id="custom-nodes-display">
              <span style="color: #6c757d; font-size: 13px;">No nodes yet</span>
            </div>
          </div>
          
          <div class="control-group">
            <label>Add Edge</label>
            <div class="input-group">
              <input type="text" id="custom-edge-from" placeholder="from" style="max-width: 80px;">
              <span style="line-height: 42px;">—</span>
              <input type="text" id="custom-edge-to" placeholder="to" style="max-width: 80px;">
              <button onclick="addCustomEdge()">Add</button>
            </div>
            <small class="helper">Both nodes must exist. No self-loops or duplicates.</small>
          </div>
          
          <div class="control-group">
            <label>Operation Log</label>
            <div class="operation-log" id="custom-log">
              <div style="color: #6c757d;">Graph operations will appear here...</div>
            </div>
          </div>
          
          <button onclick="renderCustomGraph()" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
            Visualize Graph
          </button>
          
          <button onclick="showCustomAdjacency()" class="tertiary">Show Adjacency List</button>
          
          <button onclick="resetCustomGraph()" style="background: #6c757d; margin-top: 10px;">
            Reset Graph
          </button>
        </div>

        <div class="main-content">
          <div id="custom-error" style="display:none;" class="error"></div>
          
          <div class="stats" id="custom-stats">
            <div class="stat-card">
              <div class="stat-value" id="custom-stat-nodes">0</div>
              <div class="stat-label">Nodes</div>
            </div>
            <div class="stat-card">
              <div class="stat-value" id="custom-stat-edges">0</div>
              <div class="stat-label">Edges</div>
            </div>
          </div>
          
          <div class="visualization" id="custom-visualization">
            <div class="placeholder">
              <div class="placeholder-icon">🎨</div>
              <div>Build your custom graph using the controls</div>
              <div style="margin-top: 15px; font-size: 14px; color: #6c757d;">
                <strong>Demonstrates Part 1:</strong><br>
                add_node, add_edge, get_nodes, get_edges, to_s
              </div>
            </div>
          </div>
          
          <div id="custom-adjacency-container" style="display:none;">
            <h3>Adjacency List (to_s method)</h3>
            <div class="adjacency-output" id="custom-adjacency-output"></div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script>
    let customSessionId = null;
    let customNodes = [];

    function switchTab(tabName) {
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
      
      event.target.classList.add('active');
      document.getElementById(`tab-${tabName}`).classList.add('active');
      
      if (tabName === 'custom' && !customSessionId) {
        initCustomGraph();
      }
    }

    async function initCustomGraph() {
      try {
        const response = await fetch('/custom/create', { method: 'POST' });
        const data = await response.json();
        
        if (data.success) {
          customSessionId = data.session_id;
          customNodes = [];
          updateCustomDisplay();
          logCustomOperation('✓ New graph session created', 'success');
        }
      } catch (error) {
        showCustomError('Failed to initialize: ' + error.message);
      }
    }

    async function addCustomNode() {
      const nodeName = document.getElementById('custom-node').value.trim();
      
      if (!nodeName) {
        showCustomError('Please enter a node name');
        return;
      }
      
      if (!customSessionId) {
        await initCustomGraph();
      }
      
      try {
        const response = await fetch('/custom/add_node', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `session_id=${customSessionId}&node_name=${encodeURIComponent(nodeName)}`
        });
        
        const data = await response.json();
        
        if (data.success) {
          if (!customNodes.includes(nodeName)) {
            customNodes.push(nodeName);
          }
          updateCustomDisplay();
          logCustomOperation(`✓ add_node(:${nodeName}) => :${nodeName}`, 'success');
          document.getElementById('custom-node').value = '';
          document.getElementById('custom-stat-nodes').textContent = data.nodes;
        } else {
          logCustomOperation(`✗ add_node(:${nodeName}) => nil (${data.error})`, 'error');
          showCustomError(data.error);
        }
      } catch (error) {
        showCustomError('Failed to add node: ' + error.message);
      }
    }

    async function addCustomEdge() {
      const node1 = document.getElementById('custom-edge-from').value.trim();
      const node2 = document.getElementById('custom-edge-to').value.trim();
      
      if (!node1 || !node2) {
        showCustomError('Please enter both nodes');
        return;
      }
      
      try {
        const response = await fetch('/custom/add_edge', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `session_id=${customSessionId}&node1=${encodeURIComponent(node1)}&node2=${encodeURIComponent(node2)}`
        });
        
        const data = await response.json();
        
        if (data.success) {
          logCustomOperation(`✓ add_edge(:${node1}, :${node2}) => [:${node1}, :${node2}]`, 'success');
          document.getElementById('custom-stat-edges').textContent = data.edges;
          document.getElementById('custom-edge-from').value = '';
          document.getElementById('custom-edge-to').value = '';
        } else {
          logCustomOperation(`✗ add_edge(:${node1}, :${node2}) => nil`, 'error');
          showCustomError(data.error);
        }
      } catch (error) {
        showCustomError('Failed to add edge: ' + error.message);
      }
    }

    async function renderCustomGraph() {
      if (!customSessionId) {
        showCustomError('No graph to render');
        return;
      }
      
      try {
        const response = await fetch('/custom/render', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `session_id=${customSessionId}`
        });
        
        const data = await response.json();
        
        if (data.success) {
          document.getElementById('custom-visualization').innerHTML = 
            `<img src="${data.image_url}?t=${Date.now()}" alt="Custom Graph">`;
          logCustomOperation(`✓ render() completed`, 'success');
        } else {
          showCustomError(data.error);
        }
      } catch (error) {
        showCustomError('Failed to render: ' + error.message);
      }
    }

    async function showCustomAdjacency() {
      if (!customSessionId) {
        showCustomError('No graph to display');
        return;
      }
      
      try {
        const response = await fetch('/custom/adjacency', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `session_id=${customSessionId}`
        });
        
        const data = await response.json();
        
        if (data.success) {
          let output = '';
          
          if (data.adjacency_list) {
            output += 'Adjacency List (to_s):\n';
            output += data.adjacency_list + '\n\n';
          }
          
          if (data.nodes_list) {
            output += 'get_nodes: [' + data.nodes_list + ']\n\n';
          }
          
          if (data.edges_list) {
            output += 'get_edges: [' + data.edges_list + ']';
          }
          
          document.getElementById('custom-adjacency-output').textContent = output;
          document.getElementById('custom-adjacency-container').style.display = 'block';
          logCustomOperation(`✓ to_s, get_nodes, get_edges called`, 'success');
        } else {
          showCustomError(data.error);
        }
      } catch (error) {
        showCustomError('Failed to get adjacency list: ' + error.message);
      }
    }

    async function resetCustomGraph() {
      customSessionId = null;
      customNodes = [];
      updateCustomDisplay();
      document.getElementById('custom-visualization').innerHTML = `
        <div class="placeholder">
          <div class="placeholder-icon">🎨</div>
          <div>Build your custom graph using the controls</div>
        </div>
      `;
      document.getElementById('custom-stat-nodes').textContent = '0';
      document.getElementById('custom-stat-edges').textContent = '0';
      document.getElementById('custom-log').innerHTML = 
        '<div style="color: #6c757d;">Graph reset. Ready to build new graph...</div>';
      document.getElementById('custom-adjacency-container').style.display = 'none';
      
      await initCustomGraph();
    }

    function updateCustomDisplay() {
      const display = document.getElementById('custom-nodes-display');
      
      if (customNodes.length === 0) {
        display.innerHTML = '<span style="color: #6c757d; font-size: 13px;">No nodes yet</span>';
      } else {
        display.innerHTML = customNodes.map(n => 
          `<span class="node-badge">:${n}</span>`
        ).join('');
      }
    }

    function logCustomOperation(message, type) {
      const log = document.getElementById('custom-log');
      const entry = document.createElement('div');
      entry.className = `op-${type}`;
      entry.textContent = message;
      
      if (log.querySelector('[style*="color: #6c757d"]')) {
        log.innerHTML = '';
      }
      
      log.appendChild(entry);
      log.scrollTop = log.scrollHeight;
    }

    function showCustomError(message) {
      const errorDiv = document.getElementById('custom-error');
      errorDiv.textContent = message;
      errorDiv.style.display = 'block';
      setTimeout(() => errorDiv.style.display = 'none', 5000);
    }

    // Update probability display
    document.getElementById('probability').addEventListener('input', (e) => {
      document.getElementById('prob-value').textContent = parseFloat(e.target.value).toFixed(2);
    });

    function showError(message) {
      const errorDiv = document.getElementById('error-message');
      errorDiv.textContent = message;
      errorDiv.style.display = 'block';
      setTimeout(() => errorDiv.style.display = 'none', 5000);
    }

    function showLoading(show) {
      document.getElementById('loading').classList.toggle('active', show);
    }

    async function generateGraph() {
      const nodes = document.getElementById('nodes').value;
      const probability = document.getElementById('probability').value;
      const seed = document.getElementById('seed').value;
      
      showLoading(true);
      document.getElementById('adjacency-container').style.display = 'none';
      
      try {
        const response = await fetch('/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `nodes=${nodes}&probability=${probability}&seed=${seed}`
        });
        
        const data = await response.json();
        
        if (data.error) {
          showError(data.error);
          return;
        }
        
        document.getElementById('stat-nodes').textContent = data.nodes;
        document.getElementById('stat-edges').textContent = data.edges;
        document.getElementById('stat-expected').textContent = data.expected_edges;
        document.getElementById('stats').style.display = 'grid';
        
        document.getElementById('visualization').innerHTML = 
          `<img src="${data.image_url}?t=${Date.now()}" alt="Graph Visualization">`;
        
      } catch (error) {
        showError('Failed to generate graph: ' + error.message);
      } finally {
        showLoading(false);
      }
    }

    async function runDFS() {
      const nodes = document.getElementById('nodes').value;
      const probability = document.getElementById('probability').value;
      const seed = document.getElementById('seed').value;
      const startNode = document.getElementById('start-node').value;
      
      if (!startNode) {
        showError('Please enter a start node');
        return;
      }
      
      showLoading(true);
      document.getElementById('adjacency-container').style.display = 'none';
      
      try {
        const response = await fetch('/dfs', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `nodes=${nodes}&probability=${probability}&seed=${seed}&start_node=${startNode}`
        });
        
        const data = await response.json();
        
        if (data.error) {
          showError(data.error);
          return;
        }
        
        document.getElementById('stat-nodes').textContent = data.component_size;
        document.getElementById('stat-edges').textContent = data.component_edges;
        document.getElementById('stat-expected').textContent = 'DFS Result';
        document.getElementById('stats').style.display = 'grid';
        
        document.getElementById('visualization').innerHTML = 
          `<img src="${data.image_url}?t=${Date.now()}" alt="DFS Component"><br>
           <div style="margin-top:10px; text-align:center;">
             Component nodes: ${data.component_nodes.join(', ')}
           </div>`;
        
      } catch (error) {
        showError('Failed to run DFS: ' + error.message);
      } finally {
        showLoading(false);
      }
    }

    async function showAdjacency() {
      const nodes = document.getElementById('nodes').value;
      const probability = document.getElementById('probability').value;
      const seed = document.getElementById('seed').value;
      
      showLoading(true);
      
      try {
        const response = await fetch('/adjacency', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `nodes=${nodes}&probability=${probability}&seed=${seed}`
        });
        
        const data = await response.json();
        
        if (data.error) {
          showError(data.error);
          return;
        }
        
        document.getElementById('adjacency-output').textContent = data.adjacency_list;
        document.getElementById('adjacency-container').style.display = 'block';
        
      } catch (error) {
        showError('Failed to generate adjacency list: ' + error.message);
      } finally {
        showLoading(false);
      }
    }
  </script>
</body>
</html>