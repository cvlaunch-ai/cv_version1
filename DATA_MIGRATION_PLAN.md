# PostgreSQL Migration Plan

This plan outlines the strategy to transition storage from flat files (CSV and Excel) and MySQL-style SQL definitions into a structured, unified PostgreSQL database using SQLAlchemy and Alembic.

---

## 1. Data Source Inventory

The current system captures leads into multiple flat files:

| Source Path | Format | Columns | Description |
| :--- | :--- | :--- | :--- |
| `database/leads.csv` | CSV | `Name,Email,Phone,Job Role,Timestamp` | Captured leads data |
| `database/leads_captured.csv` | CSV | `Name,Email,Phone,Job Role,Timestamp` | Secondary captured leads data |
| `database/leads_data.csv` | CSV | `Name,Email,Phone,Job Role,Timestamp` | Fallback CSV logging data |
| `database/leads_data.xlsx` | Excel | `Name,Email,Phone,Job Role,Timestamp` | Default local Excel spreadsheet logging data |

Additionally, [database/schema.sql](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/database/schema.sql) defines a MySQL-style relational schema for an assessment/interview system. This schema will be ported to PostgreSQL.

---

## 2. PostgreSQL Schema Design

We will map the existing MySQL schemas and leads flat files into structured PostgreSQL definitions.

```mermaid
erDiagram
    USERS {
        int id PK
        varchar name
        varchar email UK
        varchar password
        varchar role
    }
    LEADS {
        int id PK
        varchar name
        varchar email
        varchar phone
        varchar job_role
        timestamp timestamp
    }
    SKILLS {
        int id PK
        varchar skill_name
        int created_by_employer FK
    }
    QUESTIONS {
        int id PK
        int skill_id FK
        text question_text
    }
    INTERVIEWS {
        int id PK
        int candidate_id FK
        int skill_id FK
        varchar language
        float score
        text feedback
        timestamp created_at
    }
    RESPONSES {
        int id PK
        int interview_id FK
        int question_id FK
        text answer_text
        text ai_evaluation
    }

    USERS ||--o{ SKILLS : "creates"
    USERS ||--o{ INTERVIEWS : "undergoes"
    SKILLS ||--o{ QUESTIONS : "contains"
    SKILLS ||--o{ INTERVIEWS : "tested_in"
    INTERVIEWS ||--o{ RESPONSES : "has"
    QUESTIONS ||--o{ RESPONSES : "answered_by"
```

---

## 3. SQLAlchemy Models

We propose defining the models in a new file `backend/app/models/db.py`:

```python
from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)
    
    __table_args__ = (
        CheckConstraint(role.in_(['candidate', 'employer']), name='check_user_role'),
    )

    skills = relationship("Skill", back_populates="creator")
    interviews = relationship("Interview", back_populates="candidate")

class Lead(Base):
    __tablename__ = "leads"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=True)
    email = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    job_role = Column(String(255), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

class Skill(Base):
    __tablename__ = "skills"
    
    id = Column(Integer, primary_key=True, index=True)
    skill_name = Column(String(255), nullable=False)
    created_by_employer = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    creator = relationship("User", back_populates="skills")
    questions = relationship("Question", back_populates="skill")
    interviews = relationship("Interview", back_populates="skill")

class Question(Base):
    __tablename__ = "questions"
    
    id = Column(Integer, primary_key=True, index=True)
    skill_id = Column(Integer, ForeignKey("skills.id", ondelete="CASCADE"), nullable=True)
    question_text = Column(Text, nullable=False)
    
    skill = relationship("Skill", back_populates="questions")
    responses = relationship("Response", back_populates="question")

class Interview(Base):
    __tablename__ = "interviews"
    
    id = Column(Integer, primary_key=True, index=True)
    candidate_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    skill_id = Column(Integer, ForeignKey("skills.id", ondelete="CASCADE"), nullable=True)
    language = Column(String(50), default="English")
    score = Column(Float, default=0.0)
    feedback = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    candidate = relationship("User", back_populates="interviews")
    skill = relationship("Skill", back_populates="interviews")
    responses = relationship("Response", back_populates="interview")

class Response(Base):
    __tablename__ = "responses"
    
    id = Column(Integer, primary_key=True, index=True)
    interview_id = Column(Integer, ForeignKey("interviews.id", ondelete="CASCADE"), nullable=True)
    question_id = Column(Integer, ForeignKey("questions.id", ondelete="CASCADE"), nullable=True)
    answer_text = Column(Text, nullable=True)
    ai_evaluation = Column(Text, nullable=True)
    
    interview = relationship("Interview", back_populates="responses")
    question = relationship("Question", back_populates="responses")
```

---

## 4. Alembic Migrations

To manage database revisions:

1. **Initialization**: Run from `backend/` directory:
   ```bash
   venv\Scripts\python.exe -m alembic init alembic
   ```
2. **Configuration**:
   - In `backend/alembic.ini`, set the connection URL:
     `sqlalchemy.url = postgresql://user:password@localhost:5432/skillvoice_db`
   - In `backend/alembic/env.py`, import the declarative base metadata:
     ```python
     from app.models.db import Base
     target_metadata = Base.metadata
     ```
3. **Generation**: Generate migrations using SQLAlchemy metadata autodetect:
   ```bash
   venv\Scripts\python.exe -m alembic revision --autogenerate -m "initial_schema"
   ```
4. **Application**: Apply the tables schema to PostgreSQL:
   ```bash
   venv\Scripts\python.exe -m alembic upgrade head
   ```

---

## 5. Repository Interfaces

We will update [repositories/lead_repository.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/repositories/lead_repository.py) to write directly to PostgreSQL using SQLAlchemy sessions, wrapping transactions:

```python
from sqlalchemy.orm import Session
from app.models.db import Lead

class PostgreSQLLeadRepository:
    def __init__(self, db_session: Session):
        self.db = db_session
        
    def save_lead(self, name: str, email: str, phone: str, job_role: str) -> Lead:
        lead = Lead(
            name=name,
            email=email,
            phone=phone,
            job_role=job_role
        )
        self.db.add(lead)
        self.db.commit()
        self.db.refresh(lead)
        return lead
```

---

## 6. Storage Mapping & Data Migration Script

Below is the proposal for a standalone Python migration script (`scripts/migrate_flatfiles_to_pg.py`) that reads all flat file data sources and ingests them into the PostgreSQL table:

```python
import os
import csv
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import models
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend")))
from app.models.db import Lead, Base

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost:5432/skillvoice_db")

def migrate_csv(file_path, session):
    if not os.path.exists(file_path):
        print(f"[WARN] CSV not found: {file_path}")
        return
    
    print(f"Migrating CSV: {file_path}...")
    with open(file_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Parse timestamp safely
            ts = datetime.utcnow()
            if row.get("Timestamp"):
                try:
                    ts = datetime.strptime(row["Timestamp"], "%Y-%m-%d %H:%M:%S.%f")
                except ValueError:
                    try:
                         ts = datetime.strptime(row["Timestamp"], "%Y-%m-%d %H:%M:%S")
                    except ValueError:
                         pass
                         
            lead = Lead(
                name=row.get("Name"),
                email=row.get("Email") or row.get("Mailid"),
                phone=row.get("Phone"),
                job_role=row.get("Job Role") or row.get("JobRole"),
                timestamp=ts
            )
            session.add(lead)
    session.commit()

def migrate_excel(file_path, session):
    if not os.path.exists(file_path):
        print(f"[WARN] Excel not found: {file_path}")
        return
        
    print(f"Migrating Excel: {file_path}...")
    df = pd.read_excel(file_path)
    for _, row in df.iterrows():
        # Handle nan fields
        name = str(row.get("Name")) if pd.notna(row.get("Name")) else None
        email = str(row.get("Email")) if pd.notna(row.get("Email")) else None
        phone = str(row.get("Phone")) if pd.notna(row.get("Phone")) else None
        job_role = str(row.get("Job Role")) if pd.notna(row.get("Job Role")) else None
        
        ts = datetime.utcnow()
        if pd.notna(row.get("Timestamp")):
             # Parse timestamp or use standard datetime
             if isinstance(row["Timestamp"], datetime):
                 ts = row["Timestamp"]
             else:
                 try:
                     ts = datetime.strptime(str(row["Timestamp"]), "%Y-%m-%d %H:%M:%S.%f")
                 except ValueError:
                     pass

        lead = Lead(
            name=name,
            email=email,
            phone=phone,
            job_role=job_role,
            timestamp=ts
        )
        session.add(lead)
    session.commit()

def main():
    engine = create_engine(DATABASE_URL)
    Base.metadata.create_all(engine) # Ensure tables exist
    
    Session = sessionmaker(bind=engine)
    session = Session()
    
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    db_dir = os.path.join(project_root, "database")
    
    migrate_csv(os.path.join(db_dir, "leads.csv"), session)
    migrate_csv(os.path.join(db_dir, "leads_captured.csv"), session)
    migrate_csv(os.path.join(db_dir, "leads_data.csv"), session)
    migrate_excel(os.path.join(db_dir, "leads_data.xlsx"), session)
    
    print("✅ Migration completed successfully!")

if __name__ == "__main__":
    main()
```
