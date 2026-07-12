# Thesis Diagrams (Mermaid)

These render on GitHub and in Mermaid-aware editors (VS Code + Mermaid extension,
mermaid.live). To use in the thesis: paste into https://mermaid.live, then
**Export as PNG/SVG** and insert as a figure. Each diagram reflects the as-built
system.

---

## Figure 4.1 — System architecture (three-tier)

```mermaid
flowchart TB
    subgraph Client["Presentation Tier — React SPA (Vite + Tailwind)"]
        UI["Role-aware UI:\nCirculars · Upload · Approvals · Dashboard · Chatbot · Audit"]
        AX["Axios + JWT interceptor"]
        UI --> AX
    end

    subgraph Server["Application Tier — Flask REST API"]
        direction TB
        BP["Blueprints:\nauth · users · circulars · summaries\ndashboard · chatbot · notifications · audit"]
        SVC["Services:\nsecurity/RBAC · audit · distribution\nemail · pdf_extract · tokens"]
        AI["AI layer:\npipeline · vector_index · chatbot · llm_summarizer"]
        BP --> SVC
        BP --> AI
    end

    subgraph Data["Data Tier"]
        DB[("MySQL 8\n14 tables")]
        FAISS[("FAISS index\n+ chunk metadata")]
        CACHE[("Local model cache")]
    end

    OLLAMA["Ollama runtime\n(Llama 3.2 3B) — localhost"]

    AX -->|"HTTPS /api/*"| BP
    SVC --> DB
    AI --> DB
    AI --> FAISS
    AI --> CACHE
    AI -->|"HTTP localhost:11434"| OLLAMA

    classDef tier fill:#e6f3f3,stroke:#0e7c7b,color:#073f3f;
    class Client,Server,Data tier;
```

---

## Figure 4.2 — Entity–Relationship Diagram (core)

```mermaid
erDiagram
    USERS ||--o{ ACKNOWLEDGEMENTS : makes
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ CIRCULARS : uploads
    USERS ||--o{ CHAT_CONVERSATIONS : owns
    USERS ||--o{ AUDIT_LOG : acts
    DEPARTMENTS ||--o{ USERS : employs
    DEPARTMENTS ||--o{ CIRCULAR_DEPARTMENTS : routed
    CIRCULARS ||--o{ CIRCULAR_DEPARTMENTS : routed_to
    CIRCULARS ||--|| SUMMARIES : has
    CIRCULARS ||--o{ CLASSIFICATIONS : categorised
    CIRCULARS ||--o{ ACKNOWLEDGEMENTS : tracked
    CIRCULARS ||--o{ NOTIFICATIONS : about
    CIRCULARS ||--o{ CHANGE_REQUESTS : flagged
    CIRCULARS ||--o{ CIRCULARS : amends
    CATEGORIES ||--o{ CLASSIFICATIONS : names
    CHAT_CONVERSATIONS ||--o{ CHAT_LOG : contains

    USERS {
        int id PK
        string username
        string email
        string full_name
        string password_hash
        string role
        int department_id FK
        bool is_active
    }
    CIRCULARS {
        int id PK
        string circular_number
        string title
        date issue_date
        text extracted_text
        string priority
        string status
        datetime ack_deadline
        int uploaded_by FK
        int amends_circular_id FK
        int approved_by FK
        json distribution_intent
        datetime published_at
    }
    SUMMARIES {
        int id PK
        int circular_id FK
        text summary_text
        json entities
        int word_count
        string bart_model
        float processing_seconds
        float rouge_score
    }
    CLASSIFICATIONS {
        int id PK
        int circular_id FK
        string category
        bool is_manual
    }
    CATEGORIES {
        int id PK
        string name
    }
    ACKNOWLEDGEMENTS {
        int id PK
        int circular_id FK
        int user_id FK
        string status
        datetime read_at
        datetime acknowledged_at
        bool is_late
    }
    NOTIFICATIONS {
        int id PK
        int user_id FK
        int circular_id FK
        string message
        string link
        bool is_read
    }
    CHAT_CONVERSATIONS {
        int id PK
        int user_id FK
        int circular_id FK
        string title
    }
    CHAT_LOG {
        int id PK
        int conversation_id FK
        text question
        text answer
        json citations
    }
    AUDIT_LOG {
        int id PK
        int user_id FK
        string action
        string entity_type
        int entity_id
        string detail
        datetime created_at
    }
    DEPARTMENTS {
        int id PK
        string name
        string code
    }
    CIRCULAR_DEPARTMENTS {
        int circular_id FK
        int department_id FK
    }
    CHANGE_REQUESTS {
        int id PK
        int circular_id FK
        int requester_id FK
        string status
    }
```

---

## Figure 4.3 — Circular lifecycle (state diagram)

```mermaid
stateDiagram-v2
    [*] --> uploaded : Admin uploads PDF
    uploaded --> processing : Generate summary
    processing --> review : Summary ready
    processing --> failed : Error
    failed --> processing : Retry
    review --> pending_approval : Admin submits\n(category + departments)
    pending_approval --> published : Compliance Officer approves
    pending_approval --> review : Compliance Officer rejects\n(with reason)
    published --> processing : Regenerate summary
    published --> [*]
```

---

## Figure 5.1 — Summarization pipeline (flowchart)

```mermaid
flowchart LR
    A["PDF upload"] --> B["PyMuPDF text extraction"]
    B --> C{"Scanned or\ngarbled page?"}
    C -- yes --> D["Tesseract OCR (300 DPI)"]
    C -- no --> E["Use text layer"]
    D --> F["Clean text:\nstrip headers/footers,\ntable artefacts"]
    E --> F
    F --> G{"Ollama\navailable?"}
    G -- yes --> H["LLM summarise\n(faithful prompt:\nOverview + Key Points)"]
    G -- no --> I["Fallback:\nspaCy -> BERT select -> BART"]
    H --> J["Validate + clean output\n(strip preamble/echo)"]
    I --> J
    J --> K["Extract key terms"]
    K --> L["Store summary\n(status: review)"]
```

---

## Figure 5.2 — RAG chatbot pipeline (flowchart)

```mermaid
flowchart LR
    Q["User question"] --> RW["LLM query rewriting\n(fix typos, keep domain terms)"]
    RW --> DEN["Dense retrieval\n(SBERT + FAISS)"]
    RW --> SPA["Sparse retrieval\n(BM25)"]
    DEN --> RRF["Reciprocal Rank Fusion"]
    SPA --> RRF
    RRF --> SCOPE["Scope filter\n(circular / global,\ndemote superseded)"]
    SCOPE --> CTX["Top-k passages as context"]
    CTX --> GEN["LLM grounded generation\n(cite circular numbers,\nrefuse if unsupported)"]
    GEN --> ANS["Answer + citations"]
    ANS --> LOG["Persist to conversation"]
```

---

## Figure 5.3 — Four-eyes approval workflow (sequence diagram)

```mermaid
sequenceDiagram
    actor Admin as Administrator (Maker)
    participant Sys as System
    actor CO as Compliance Officer (Checker)
    actor Emp as Employees

    Admin->>Sys: Upload circular + generate summary
    Sys-->>Admin: Summary (status: review)
    Admin->>Sys: Submit for approval\n(category + departments)
    Sys->>Sys: status = pending_approval
    Sys-->>CO: Notify: awaiting approval
    CO->>Sys: Review summary
    alt Approve
        CO->>Sys: Approve
        Sys->>Sys: status = published; record approver
        Sys->>Emp: Route + notify + email
        Sys-->>Admin: Notify: approved & published
    else Reject
        CO->>Sys: Reject (with reason)
        Sys->>Sys: status = review
        Sys-->>Admin: Notify: rejected + reason
    end
    Note over Sys: Every step written to immutable audit log
```

---

## Figure 5.4 — Distribution & acknowledgement flow

```mermaid
flowchart TB
    P["Circular published"] --> R["Resolve target departments\n(distribution_intent)"]
    R --> U["Active Employees & Managers\nin those departments"]
    U --> A["Create Acknowledgement (Unread)"]
    U --> N["In-app notification (deep link)"]
    U --> E["Email with summary"]
    A --> O["Employee opens -> Read"]
    O --> AK["Employee confirms -> Acknowledged"]
    A --> RM{"Deadline near/passed\n& not acknowledged?"}
    RM -- yes --> REM["Reminder + flag late"]
```
