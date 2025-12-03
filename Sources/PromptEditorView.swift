import SwiftUI

struct PromptEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplateId: String = "default"
    @State private var editedPrompt: String = ""
    @State private var isCreatingNew: Bool = false
    @State private var newTemplateName: String = ""
    @State private var newTemplateCategory: PromptTemplate.TemplateCategory = .general
    @FocusState private var isEditorFocused: Bool
    @State private var monitor: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            // Template selector
            HStack {
                Text("Template:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedTemplateId) {
                    ForEach(appState.templateManager.templates) { template in
                        Text(template.name).tag(template.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedTemplateId) { _, newValue in
                    loadTemplate(id: newValue)
                }
                
                Spacer()
                
                Button(action: {
                    isCreatingNew.toggle()
                    if isCreatingNew {
                        newTemplateName = ""
                        editedPrompt = ""
                    } else {
                        loadTemplate(id: selectedTemplateId)
                    }
                }) {
                    Label(isCreatingNew ? "Cancel New" : "New Template", systemImage: isCreatingNew ? "xmark.circle" : "plus.circle")
                }
                .buttonStyle(.borderless)
            }
            
            // New template fields
            if isCreatingNew {
                VStack(spacing: 8) {
                    HStack {
                        Text("Name:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                        
                        TextField("Template name", text: $newTemplateName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Category:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                        
                        Picker("", selection: $newTemplateCategory) {
                            ForEach(PromptTemplate.TemplateCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            // Template description (for built-in templates)
            if !isCreatingNew, let template = appState.templateManager.template(withId: selectedTemplateId) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(8)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(6)
            }
            
            // Prompt editor
            VStack(alignment: .leading, spacing: 6) {
                Text("Proofreading Instructions:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedPrompt)
                    .font(.system(size: 13, design: .default))
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 180)
                    .focused($isEditorFocused)
                    .disabled(!isCreatingNew && currentTemplate?.isBuiltIn == true)
                
                if currentTemplate?.isBuiltIn == true {
                    Text("Built-in templates cannot be edited. Create a new template or select a custom one.")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Note: System rules for consistent AI behavior are automatically added.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                if !isCreatingNew && currentTemplate?.isBuiltIn == false {
                    Button("Delete Template") {
                        if let template = currentTemplate {
                            appState.templateManager.deleteTemplate(template)
                            selectedTemplateId = "default"
                            loadTemplate(id: "default")
                        }
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button(isCreatingNew ? "Create" : "Save") {
                    saveTemplate()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(isCreatingNew && newTemplateName.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 520, height: isCreatingNew ? 480 : 420)
        .onAppear {
            selectedTemplateId = appState.selectedTemplate
            loadTemplate(id: selectedTemplateId)
            isEditorFocused = true
            setupKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }
    
    private var currentTemplate: PromptTemplate? {
        appState.templateManager.template(withId: selectedTemplateId)
    }
    
    private func loadTemplate(id: String) {
        if let template = appState.templateManager.template(withId: id) {
            editedPrompt = template.prompt
        }
    }
    
    private func saveTemplate() {
        if isCreatingNew {
            // Create new template
            let newTemplate = PromptTemplate(
                name: newTemplateName,
                description: "Custom template",
                prompt: editedPrompt,
                isBuiltIn: false,
                category: newTemplateCategory
            )
            appState.templateManager.addTemplate(newTemplate)
            appState.selectedTemplate = newTemplate.id
        } else if let template = currentTemplate, !template.isBuiltIn {
            // Update existing custom template
            let updatedTemplate = PromptTemplate(
                id: template.id,
                name: template.name,
                description: template.description,
                prompt: editedPrompt,
                isBuiltIn: false,
                category: template.category
            )
            appState.templateManager.updateTemplate(updatedTemplate)
        } else {
            // Just update the selected template for built-in templates
            appState.selectedTemplate = selectedTemplateId
        }
    }
    
    private func setupKeyMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                dismiss()
                return nil
            }
            return event
        }
    }
    
    private func removeKeyMonitor() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}