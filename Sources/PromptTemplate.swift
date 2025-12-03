import Foundation

/// Represents a proofreading prompt template
struct PromptTemplate: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let prompt: String
    let isBuiltIn: Bool
    let category: TemplateCategory
    
    enum TemplateCategory: String, Codable, CaseIterable {
        case general = "General"
        case academic = "Academic"
        case business = "Business"
        case casual = "Casual"
        case technical = "Technical"
        case creative = "Creative"
    }
    
    init(id: String = UUID().uuidString, name: String, description: String, prompt: String, isBuiltIn: Bool = false, category: TemplateCategory = .general) {
        self.id = id
        self.name = name
        self.description = description
        self.prompt = prompt
        self.isBuiltIn = isBuiltIn
        self.category = category
    }
    
    /// Built-in templates
    static let builtInTemplates: [PromptTemplate] = [
        PromptTemplate(
            id: "default",
            name: "Default",
            description: "General proofreading for non-native English speakers",
            prompt: "You are an English proofreading assistant for non-native speakers. Correct grammar, spelling, punctuation, and word choice errors. Pay special attention to: articles (a/an/the), prepositions, verb tenses, subject-verb agreement, plural forms, and natural English phrasing. Preserve the original meaning, tone, and formatting exactly.",
            isBuiltIn: true,
            category: .general
        ),
        PromptTemplate(
            id: "academic",
            name: "Academic Writing",
            description: "Formal academic and research writing",
            prompt: "You are an academic writing assistant. Correct grammar, spelling, and punctuation while maintaining formal academic tone. Focus on: precise terminology, clear argumentation, proper citation format preservation, subject-verb agreement, and scholarly language. Ensure clarity and conciseness while preserving the original meaning and academic rigor.",
            isBuiltIn: true,
            category: .academic
        ),
        PromptTemplate(
            id: "business",
            name: "Business Communication",
            description: "Professional emails and business documents",
            prompt: "You are a business writing assistant. Correct grammar, spelling, and punctuation while maintaining professional tone. Focus on: clarity, conciseness, professional language, proper email etiquette, and business terminology. Ensure the message is clear, polite, and action-oriented while preserving the original intent.",
            isBuiltIn: true,
            category: .business
        ),
        PromptTemplate(
            id: "casual",
            name: "Casual Writing",
            description: "Informal messages and social media",
            prompt: "You are a casual writing assistant. Correct obvious grammar and spelling errors while preserving informal tone and style. Maintain conversational language, contractions, and casual expressions. Only fix clear mistakes without making the text overly formal.",
            isBuiltIn: true,
            category: .casual
        ),
        PromptTemplate(
            id: "technical",
            name: "Technical Documentation",
            description: "Technical writing and documentation",
            prompt: "You are a technical writing assistant. Correct grammar, spelling, and punctuation while maintaining technical accuracy. Focus on: precise terminology, clear instructions, consistent formatting, proper use of technical terms, and logical flow. Preserve code snippets, commands, and technical specifications exactly.",
            isBuiltIn: true,
            category: .technical
        ),
        PromptTemplate(
            id: "creative",
            name: "Creative Writing",
            description: "Stories, articles, and creative content",
            prompt: "You are a creative writing assistant. Correct grammar, spelling, and punctuation while preserving the author's unique voice and style. Focus on: narrative flow, dialogue punctuation, descriptive language, and stylistic choices. Maintain creative expressions and intentional stylistic devices while fixing clear errors.",
            isBuiltIn: true,
            category: .creative
        )
    ]
}

/// Manages prompt templates
@MainActor
class TemplateManager: ObservableObject {
    @Published var templates: [PromptTemplate] = []
    
    private let customTemplatesKey = "customPromptTemplates"
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadTemplates()
    }
    
    /// Load all templates (built-in + custom)
    func loadTemplates() {
        templates = PromptTemplate.builtInTemplates
        
        // Load custom templates
        if let data = userDefaults.data(forKey: customTemplatesKey),
           let customTemplates = try? JSONDecoder().decode([PromptTemplate].self, from: data) {
            templates.append(contentsOf: customTemplates)
        }
    }
    
    /// Save custom templates
    private func saveCustomTemplates() {
        let customTemplates = templates.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(customTemplates) {
            userDefaults.set(data, forKey: customTemplatesKey)
        }
    }
    
    /// Add a new custom template
    func addTemplate(_ template: PromptTemplate) {
        var newTemplate = template
        newTemplate = PromptTemplate(
            id: UUID().uuidString,
            name: template.name,
            description: template.description,
            prompt: template.prompt,
            isBuiltIn: false,
            category: template.category
        )
        templates.append(newTemplate)
        saveCustomTemplates()
    }
    
    /// Update an existing custom template
    func updateTemplate(_ template: PromptTemplate) {
        guard !template.isBuiltIn else { return }
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveCustomTemplates()
        }
    }
    
    /// Delete a custom template
    func deleteTemplate(_ template: PromptTemplate) {
        guard !template.isBuiltIn else { return }
        templates.removeAll { $0.id == template.id }
        saveCustomTemplates()
    }
    
    /// Get template by ID
    func template(withId id: String) -> PromptTemplate? {
        templates.first { $0.id == id }
    }
    
    /// Get templates by category
    func templates(inCategory category: PromptTemplate.TemplateCategory) -> [PromptTemplate] {
        templates.filter { $0.category == category }
    }
}
