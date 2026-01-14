import SwiftUI

/// Main view for displaying an interactive infographic
struct InfographicView: View {
    let infographic: InteractiveInfographic
    @State private var expandedNodes: Set<String> = []
    @State private var showCodeModal = false
    @State private var selectedCodeNode: InfographicNode?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Repository Header
                    repositoryHeader
                    
                    // Nested node boxes
                    ForEach(infographic.root.children) { child in
                        InfographicNodeBox(
                            node: child,
                            expandedNodes: $expandedNodes,
                            onCodeTap: { node in
                                selectedCodeNode = node
                                showCodeModal = true
                            }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Infographic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: expandAll) {
                            Image(systemName: "plus.square.on.square")
                        }
                        .foregroundColor(.textSecondary)
                        
                        Button(action: collapseAll) {
                            Image(systemName: "minus.square")
                        }
                        .foregroundColor(.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showCodeModal) {
                if let node = selectedCodeNode {
                    CodeModalView(node: node)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Repository Header
    
    private var repositoryHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Badge
            Text("REPOSITORY")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(InfographicNodeType.repo.color)
                .cornerRadius(12)
            
            // Title
            HStack(spacing: 10) {
                Image(systemName: infographic.root.iconName)
                    .font(.title2)
                    .foregroundColor(InfographicNodeType.repo.color)
                
                Text(infographic.root.label)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            
            // Description
            if let description = infographic.root.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Divider()
                .background(Color.bgTertiary)
            
            // Pipeline overview
            if let overview = infographic.pipelineOverview {
                HStack(alignment: .top, spacing: 8) {
                    Text("📊")
                    Text(overview)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // GitHub link
            if let url = URL(string: infographic.repoUrl) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(InfographicNodeType.repo.color, lineWidth: 2)
                )
        )
    }
    
    // MARK: - Actions
    
    private func expandAll() {
        func collectIds(_ node: InfographicNode) {
            expandedNodes.insert(node.id)
            for child in node.children {
                collectIds(child)
            }
        }
        collectIds(infographic.root)
    }
    
    private func collapseAll() {
        expandedNodes.removeAll()
    }
}

// MARK: - Node Box View

struct InfographicNodeBox: View {
    let node: InfographicNode
    @Binding var expandedNodes: Set<String>
    let onCodeTap: (InfographicNode) -> Void
    
    private var isExpanded: Bool {
        expandedNodes.contains(node.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (tappable)
            nodeHeader
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if isExpanded {
                            expandedNodes.remove(node.id)
                        } else {
                            expandedNodes.insert(node.id)
                        }
                    }
                }
            
            // Children (when expanded)
            if isExpanded {
                nodeContent
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.sm)
                    .background(Color.black.opacity(0.15))
            }
        }
        .background(node.type.backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(node.nodeColor, lineWidth: 1)
        )
        .overlay(
            // Left accent bar
            HStack {
                Rectangle()
                    .fill(node.nodeColor)
                    .frame(width: 4)
                Spacer()
            }
            .cornerRadius(10)
        )
    }
    
    // MARK: - Node Header
    
    private var nodeHeader: some View {
        HStack(spacing: 10) {
            // Expand/collapse indicator
            Image(systemName: node.hasChildren || node.isCodeBlock ? "chevron.right" : "circle.fill")
                .font(.system(size: node.hasChildren || node.isCodeBlock ? 12 : 6))
                .foregroundColor(.textSecondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .frame(width: 20)
            
            // Icon
            Image(systemName: node.iconName)
                .font(.system(size: 16))
                .foregroundColor(node.nodeColor)
            
            // Label
            Text(node.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Badge
            Text(node.type.displayName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(node.nodeColor)
                .cornerRadius(8)
            
            // Child count
            if node.hasChildren {
                Text("(\(node.children.count))")
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 12)
        .background(node.nodeColor.opacity(0.1))
    }
    
    // MARK: - Node Content
    
    private var nodeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Metadata
            nodeMetadata
            
            // Code preview (for code blocks)
            if node.isCodeBlock, let codeMeta = node.codeMetadata {
                codePreview(codeMeta)
            }
            // Children (for non-code nodes)
            else {
                ForEach(node.children) { child in
                    InfographicNodeBox(
                        node: child,
                        expandedNodes: $expandedNodes,
                        onCodeTap: onCodeTap
                    )
                }
            }
        }
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Metadata Views
    
    @ViewBuilder
    private var nodeMetadata: some View {
        // Phase metadata
        if let phaseMeta = node.phaseMetadata, let purpose = phaseMeta.phasePurpose {
            metadataRow(label: "Purpose", value: purpose)
        }
        
        // Step metadata
        if let stepMeta = node.stepMetadata {
            // Source/Target nodes
            if let sources = stepMeta.sourceNodes, !sources.isEmpty {
                ioNodesView(title: "📥 Inputs", nodes: sources, isSource: true)
            }
            if let targets = stepMeta.targetNodes, !targets.isEmpty {
                ioNodesView(title: "📤 Outputs", nodes: targets, isSource: false)
            }
            
            // Script and notes
            HStack(spacing: Spacing.md) {
                if let script = stepMeta.processScript {
                    metadataChip(label: "Script", value: script, color: .accentPrimary)
                }
                if let notes = stepMeta.notes {
                    metadataChip(label: "Note", value: notes, color: .textSecondary)
                }
            }
            
            // Connections
            if let connections = node.connections, !connections.isEmpty {
                connectionsView(connections)
            }
        }
        
        // File metadata
        if let fileMeta = node.fileMetadata {
            HStack(spacing: Spacing.md) {
                if let path = fileMeta.filePath {
                    metadataChip(label: "Path", value: path, color: .accentPrimary)
                }
                if let lang = fileMeta.language {
                    metadataChip(label: "Language", value: lang, color: .textSecondary)
                }
                if let lines = fileMeta.lineCount {
                    metadataChip(label: "Lines", value: "\(lines)", color: .textSecondary)
                }
            }
            
            if let url = fileMeta.githubUrl, let linkUrl = URL(string: url) {
                Link(destination: linkUrl) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                    .font(.caption)
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        
        // Function metadata
        if let funcMeta = node.functionMetadata {
            if let signature = funcMeta.signature {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Signature")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                    Text(signature)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.accentPrimary)
                        .padding(8)
                        .background(Color.bgPrimary)
                        .cornerRadius(6)
                }
            }
            
            HStack(spacing: Spacing.md) {
                if let start = funcMeta.lineStart, let end = funcMeta.lineEnd {
                    metadataChip(label: "Lines", value: "\(start)-\(end)", color: .textSecondary)
                }
            }
            
            if let docstring = funcMeta.docstring {
                Text(docstring)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.textSecondary)
            }
            
            if let url = funcMeta.githubUrl, let linkUrl = URL(string: url) {
                Link(destination: linkUrl) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                    .font(.caption)
                    .foregroundColor(.accentPrimary)
                }
            }
        }
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.textTertiary)
            Text(value)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
    
    private func metadataChip(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.caption2)
                .foregroundColor(.textTertiary)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.2))
        .cornerRadius(4)
    }
    
    private func ioNodesView(title: String, nodes: [String], isSource: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
            
            FlowLayout(spacing: 6) {
                ForEach(nodes, id: \.self) { node in
                    HStack(spacing: 4) {
                        Text(isSource ? "←" : "→")
                            .foregroundColor(isSource ? .success : .warning)
                        Text(node)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.bgTertiary)
                    .cornerRadius(4)
                    .overlay(
                        HStack {
                            Rectangle()
                                .fill(isSource ? Color.success : Color.warning)
                                .frame(width: 3)
                            Spacer()
                        }
                        .cornerRadius(4)
                    )
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
    
    private func connectionsView(_ connections: [Connection]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🔗 Data Flow")
                .font(.caption2)
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
            
            FlowLayout(spacing: 6) {
                ForEach(connections) { conn in
                    HStack(spacing: 4) {
                        Text(conn.isOutgoing ? "→" : "←")
                            .foregroundColor(.success)
                        Text(conn.label ?? "connects to")
                            .foregroundColor(.textSecondary)
                        Text(conn.targetId)
                            .foregroundColor(.accentPrimary)
                    }
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.bgTertiary)
                    .cornerRadius(4)
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
    
    // MARK: - Code Preview
    
    private func codePreview(_ meta: CodeMetadata) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(meta.language ?? "code")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                if let url = meta.githubUrl, let linkUrl = URL(string: url) {
                    Link(destination: linkUrl) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                            Text("View on GitHub")
                        }
                        .font(.caption)
                        .foregroundColor(.accentPrimary)
                    }
                }
            }
            .padding(10)
            .background(Color.bgTertiary)
            
            // Code
            ScrollView(.horizontal, showsIndicators: false) {
                Text(meta.code ?? "// No code available")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .padding(12)
            }
            .frame(maxHeight: 300)
            .background(Color.bgPrimary)
            
            // Annotations
            if let annotations = meta.annotations, !annotations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("💡 Annotations")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                        .textCase(.uppercase)
                    
                    ForEach(annotations) { ann in
                        HStack(alignment: .top, spacing: 8) {
                            Text("Line \(ann.line):")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.warning)
                            Text(ann.comment)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(8)
                        .background(Color.bgTertiary)
                        .cornerRadius(4)
                    }
                }
                .padding(10)
                .background(Color.bgSecondary)
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.bgTertiary, lineWidth: 1)
        )
    }
}

// MARK: - Code Modal View

struct CodeModalView: View {
    let node: InfographicNode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let meta = node.codeMetadata {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        // Metadata
                        HStack(spacing: Spacing.md) {
                            if let path = meta.filePath {
                                Label(path, systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            if let lang = meta.language {
                                Label(lang, systemImage: "chevron.left.forwardslash.chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            if let start = meta.lineStart, let end = meta.lineEnd {
                                Label("Lines \(start)-\(end)", systemImage: "number")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding()
                        .background(Color.bgSecondary)
                        .cornerRadius(8)
                        
                        // Code
                        ScrollView([.horizontal, .vertical]) {
                            Text(meta.code ?? "// No code available")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.textPrimary)
                                .padding()
                        }
                        .background(Color.bgPrimary)
                        .cornerRadius(8)
                        
                        // Annotations
                        if let annotations = meta.annotations, !annotations.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("💡 Annotations")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                
                                ForEach(annotations) { ann in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("Line \(ann.line)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.warning)
                                            .frame(width: 60, alignment: .leading)
                                        Text(ann.comment)
                                            .font(.subheadline)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.bgTertiary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle(node.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if let url = node.codeMetadata?.githubUrl, let linkUrl = URL(string: url) {
                        Link(destination: linkUrl) {
                            Image(systemName: "safari")
                                .foregroundColor(.accentPrimary)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Flow Layout (for wrapping tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    // Sample preview with mock data
    let sampleNode = InfographicNode(
        id: "root",
        type: .repo,
        label: "Sample Repository",
        description: "A sample repository for preview",
        children: [
            InfographicNode(
                id: "phase-1",
                type: .phase,
                label: "Ingestion",
                description: "Data ingestion phase",
                children: [],
                visualHint: nil,
                phaseMetadata: PhaseMetadata(phaseId: "1", phasePurpose: "Load data from sources"),
                stepMetadata: nil,
                fileMetadata: nil,
                functionMetadata: nil,
                codeMetadata: nil,
                connections: nil
            )
        ],
        visualHint: nil,
        phaseMetadata: nil,
        stepMetadata: nil,
        fileMetadata: nil,
        functionMetadata: nil,
        codeMetadata: nil,
        connections: nil
    )
    
    let sample = InteractiveInfographic(
        version: "2.0",
        schema: "interactive-infographic",
        repoUrl: "https://github.com/example/repo",
        repoName: "sample-repo",
        repoSummary: "A sample repository",
        pipelineOverview: "Sample pipeline overview",
        generatedAt: "2026-01-14",
        root: sampleNode
    )
    
    return InfographicView(infographic: sample)
}
