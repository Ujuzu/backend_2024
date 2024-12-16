# Ujuzi STEMex Solution

| <img src="./ujuzi.png" width="800"/> |
|:---:|

## Overview

Ujuzi STEMex is an innovative educational platform designed to bridge the technology skills gap by providing immersive, hands-on learning experiences in STEM disciplines. Our integrated solution combines web platforms, physical equipment, and gamified simulations to transform how students learn complex technical concepts.

### Key Features

- **Interactive Learning Modules**: Comprehensive educational experiences in:
  - Electricity
  - Electronics
  - Optics/Photonics
  - Embedded Programming

- **Hands-On Approach**: Connect theoretical physics concepts with real-world applications
- **Gamified Learning**: Engaging simulations that make technical learning enjoyable
- **Skill-Bridging Curriculum**: Designed to close the practical skills gap in STEM education

## Technology Stack

### Backend
- **Headless CMS**: Strapi
- **Database**: PostgreSQL
- **Deployment**: [To be determined]

### Frontend
- [ React, Next.js]

### Physical Equipment
- [Specific hardware details to be added]

## Getting Started

### Prerequisites
- Node.js (v18.x or higher)
- npm
- PostgreSQL
- Git

### Backend Setup

1. Clone the repository
```bash
git clone https://github.com/Ujuzu/backend_2024.git
cd backend_2024/backend
```

2. Run the setup script
```bash
chmod u+x strapi_setup.sh
./strapi_setup.sh
```

3. Start the development server
```bash
npm run develop
```

## Development Workflow

### Database Migrations
```bash
npm run strapi db:migrate
```

### Creating Admin User
```bash
npm run strapi admin:create-user
```

## Project Structure
```
ujuzi-stemex/
│
├── backend/              # Strapi backend
│   ├── config/           # Configuration files
│   ├── src/              # Custom plugins, middlewares
│   └── database/         # Database migrations
│
```

## Roadmap
- [ ] Complete backend development
- [ ] Develop frontend interfaces
- [ ] Integrate hardware components
- [ ] Create initial learning modules
- [ ] Implement user authentication
- [ ] Design gamification systems

## Contributing
[Contribution guidelines to be added]

## License
[License information to be specified]

## Contact
- Project Lead: [Jesse]
- Email: [Contact Email]
- Website: []

---

**Empowering the next generation of STEM learners through interactive, practical education.**
