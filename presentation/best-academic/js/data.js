/* Best Academic Education Portal — Weekly Sprint Development Plan
   Source of truth for the formal document and the presentation.
   Wording follows the supplied development timeline. No scope has been added. */

const PLAN = {
  project: "Best Academic Education Portal",
  documentName: "Best Academic Education Portal — Weekly Sprint Development Plan",
  title: "Weekly Sprint Development Plan",
  subtitle: "Module-wise Development Roadmap & Sprint Deliverables",
  coverLine: "Module-wise Development Roadmap",
  version: "To Be Confirmed",
  documentStatus: "To Be Confirmed",
  preparedFor: "To Be Confirmed",
  preparedBy: "To Be Confirmed",
  date: "2 October 2026",
  lastUpdated: "2 October 2026",
  developmentDuration: "40 Working Days",
  qaDuration: "10 Working Days",
  totalDuration: "50 Working Days",
  phase: "Phase 1",

  overview: {
    objective:
      "Plan the Phase 1 development of the Best Academic Education Portal: the Student Website, the Admin Panel, the Live Office Screen, and Lead Routing, including the related master data, enquiry, counselling, content, search, and filter work described in this plan.",
    approach:
      "Development is organised as eight weekly sprints of five working days each. Each sprint moves from understanding and design into build, then into integration and development closure. Testing is not placed inside those forty days.",
    sprintStructure:
      "Week 1 is research and technical analysis. Week 2 is UI/UX design and the frontend foundation. Weeks 3 and 4 complete the Student Website. Week 5 builds the Admin Panel. Week 6 builds Live Office and Lead Routing, with one item held for technical feasibility. Week 7 completes remaining backend, API, business rules, and system integration. Week 8 closes development and prepares deployment and QA handover.",
    sequence:
      "Research and technical analysis, then UI/UX and frontend foundation, then Student Website frontend and backend, then the remaining Student Website modules and integration, then the Admin Panel, then Live Office and Lead Routing, then backend completion and system integration, then development closure and deployment preparation, then a separate QA phase.",
    timeline:
      "Total development duration is 40 working days. Testing / QA is an additional 10 working days. The total project working timeline is 50 working days."
  },

  majorModules: [
    "Student Website",
    "Qualification & Stream",
    "Course Explorer",
    "College Discovery & College Information",
    "Student Enquiry",
    "Banner, Announcements & Campaign / Scholarship Content",
    "General Counselling",
    "Search, Filter & Recommendation",
    "Admin Panel",
    "College Master",
    "Course & Filter Master",
    "Enquiry Management",
    "Live Office Screen",
    "Lead Routing & Counsellor Handling"
  ],

  sprints: [
    {
      id: 1,
      code: "01",
      week: "Week 1",
      title: "Research & Technical Analysis",
      daysLabel: "Day 1–5",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Research & Technical Analysis",
      distributionFocus: "Research & Technical Analysis",
      objective:
        "Study the complete Phase 1 requirements and the student, admin, Live Office, and lead-routing journeys. Produce a finalized technical understanding, an architecture plan, an API list, a database plan, and a development breakdown.",
      modules: [
        "Student Website",
        "Admin Panel",
        "Live Office Screen",
        "Lead Routing",
        "College Master",
        "Course & Filter Master",
        "Enquiry"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 1",
          name: "Complete Application & Requirement Study",
          items: [
            "Study complete Phase 1 requirements",
            "Student Website analysis",
            "Admin Panel analysis",
            "Live Office Screen analysis",
            "Lead Routing analysis",
            "Identify all modules and sub-modules",
            "Understand complete user journey"
          ]
        },
        {
          n: "02",
          day: "Day 2",
          name: "Student Journey & Business Flow",
          items: [
            "Qualification selection flow",
            "Stream selection",
            "Course selection",
            "College discovery",
            "College details",
            "Enquiry flow",
            "General counselling flow",
            "Student data collection requirements"
          ]
        },
        {
          n: "03",
          day: "Day 3",
          name: "Admin & Data Structure Analysis",
          items: [
            "College Master requirements",
            "Course & Filter Master",
            "College/course relationship",
            "Scholarship information",
            "Fees/seats and related college data",
            "Enquiry data structure",
            "Admin management requirements"
          ]
        },
        {
          n: "04",
          day: "Day 4",
          name: "Backend / API / Database Analysis",
          items: [
            "Database entity identification",
            "Table/relationship planning",
            "API requirement identification",
            "Student APIs",
            "College APIs",
            "Course APIs",
            "Enquiry APIs",
            "Lead routing APIs",
            "Admin APIs",
            "Authentication requirements",
            "Third-party dependency analysis"
          ]
        },
        {
          n: "05",
          day: "Day 5",
          name: "Lead Routing & Technical Feasibility",
          items: [
            "Best Academy first-priority flow",
            "Counsellor handling flow",
            "College assignment flow",
            "Lead status requirements",
            "Routing conditions",
            "Tracking requirements",
            "Identify technically uncertain requirements",
            "Final development task breakdown"
          ]
        }
      ],
      technical: {
        api: [
          "API requirement identification",
          "Student APIs",
          "College APIs",
          "Course APIs",
          "Enquiry APIs",
          "Lead routing APIs",
          "Admin APIs"
        ],
        database: [
          "Database entity identification",
          "Table/relationship planning"
        ],
        other: [
          "Authentication requirements",
          "Third-party dependency analysis"
        ]
      },
      business: [
        "Qualification selection flow",
        "Stream selection",
        "Course selection",
        "College discovery",
        "College details",
        "Enquiry flow",
        "General counselling flow",
        "Student data collection requirements",
        "Best Academy first-priority flow",
        "Counsellor handling flow",
        "College assignment flow",
        "Lead status requirements",
        "Routing conditions",
        "Tracking requirements"
      ],
      dependencies: [
        "Complete Phase 1 requirements, as the subject of Day 1 study",
        "Third-party dependencies, to be identified during analysis",
        "Technically uncertain requirements, to be identified on Day 5"
      ],
      deliverables: [
        "Finalized technical understanding, architecture plan, API list, database plan and development breakdown."
      ],
      notes: [
        "Week 1 is analysis and planning. It identifies APIs, data, authentication needs, third-party dependencies, and technically uncertain requirements. It does not treat later implementation items as already confirmed.",
        "Database structure is planned here through entity identification and table/relationship planning, and is finalized later in the plan."
      ]
    },
    {
      id: 2,
      code: "02",
      week: "Week 2",
      title: "UI/UX Design & Frontend Foundation",
      daysLabel: "Day 6–10",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "UI/UX Design & Frontend Foundation",
      distributionFocus: "UI/UX Design",
      objective:
        "Design the Phase 1 interface and the reusable frontend component foundation: design system, Student Website, discovery, enquiry, Admin Panel, and Live Office / Lead Routing screens.",
      modules: [
        "Design System",
        "Student Website",
        "Course Explorer",
        "College Discovery",
        "Enquiry",
        "General Counselling",
        "Admin Panel",
        "Live Office Screen",
        "Lead Routing"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 6",
          name: "Design System",
          items: [
            "Project UI foundation",
            "Typography",
            "Color system",
            "Buttons",
            "Cards",
            "Form components",
            "Input components",
            "Dropdowns",
            "Modal components",
            "Table components",
            "Common responsive components"
          ]
        },
        {
          n: "02",
          day: "Day 7",
          name: "Student Website UI",
          items: [
            "Homepage",
            "Banner slider",
            "Qualification selection",
            "Stream selection",
            "Course selection",
            "Navigation flow",
            "Responsive layouts"
          ]
        },
        {
          n: "03",
          day: "Day 8",
          name: "Student Discovery UI",
          items: [
            "Course Explorer",
            "Top 10 Colleges",
            "College listing",
            "College details",
            "Search/filter interface",
            "Scholarship information section",
            "General counselling UI"
          ]
        },
        {
          n: "04",
          day: "Day 9",
          name: "Enquiry UI",
          items: [
            "Step-by-step enquiry form",
            "Student information",
            "Qualification/marks",
            "Course interest",
            "Contact details",
            "Enquiry confirmation",
            "Validation/error states"
          ]
        },
        {
          n: "05",
          day: "Day 10",
          name: "Admin + Office UI",
          items: [
            "Admin Dashboard UI",
            "College Master UI",
            "Course & Filter Master UI",
            "Live Office Screen UI",
            "Lead Routing UI",
            "Final UI consistency review"
          ]
        }
      ],
      technical: {
        frontend: [
          "Project UI foundation",
          "Typography",
          "Color system",
          "Buttons",
          "Cards",
          "Form components",
          "Input components",
          "Dropdowns",
          "Modal components",
          "Table components",
          "Common responsive components",
          "Student Website screens listed for Days 7–9",
          "Admin Dashboard UI",
          "College Master UI",
          "Course & Filter Master UI",
          "Live Office Screen UI",
          "Lead Routing UI",
          "Responsive layouts",
          "Final UI consistency review"
        ]
      },
      deliverables: [
        "Complete Phase 1 UI/UX and reusable frontend component foundation."
      ],
      notes: [
        "This sprint produces the Phase 1 UI/UX and the reusable frontend component foundation. Backend and API implementation begins in the following sprint."
      ]
    },
    {
      id: 3,
      code: "03",
      week: "Week 3",
      title: "Student Website Frontend + Backend",
      daysLabel: "Day 11–15",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Student Website Frontend + Backend",
      distributionFocus: "Student Website – Frontend + Backend + API",
      objective:
        "Set up the frontend project and build the Student Website core: qualification and stream, Course Explorer, college discovery, and student enquiry, with the related backend and API work.",
      modules: [
        "Frontend Project Setup",
        "Qualification & Stream",
        "Course Explorer",
        "College Discovery",
        "Student Enquiry"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 11",
          name: "Frontend Project Setup",
          items: [
            "Frontend project architecture",
            "Routing",
            "Reusable components",
            "Layout",
            "Header/footer",
            "Responsive framework",
            "API service structure",
            "Environment configuration"
          ]
        },
        {
          n: "02",
          day: "Day 12",
          name: "Qualification & Stream Module",
          groups: [
            { label: "Frontend", items: ["Qualification selection", "Stream selection", "Dynamic selection"] },
            { label: "Backend", items: ["Qualification master API", "Stream master API", "Data relationships"] }
          ]
        },
        {
          n: "03",
          day: "Day 13",
          name: "Course Explorer",
          groups: [
            { label: "Frontend", items: ["Course listing", "Course categories", "Course details", "Course selection"] },
            { label: "Backend/API", items: ["Course master API", "Course filtering API", "Stream-course mapping API"] }
          ]
        },
        {
          n: "04",
          day: "Day 14",
          name: "College Discovery",
          groups: [
            { label: "Frontend", items: ["College listing", "Top colleges", "College details", "College search/filter"] },
            { label: "Backend/API", items: ["College master API", "College details API", "Course/college mapping API"] }
          ]
        },
        {
          n: "05",
          day: "Day 15",
          name: "Student Enquiry",
          groups: [
            { label: "Frontend", items: ["Enquiry form", "Step-by-step flow", "Validation", "Submission"] },
            { label: "Backend/API", items: ["Enquiry API", "Student enquiry data storage", "Validation", "Enquiry status foundation"] }
          ]
        }
      ],
      technical: {
        frontend: [
          "Frontend project architecture",
          "Routing",
          "Reusable components",
          "Layout",
          "Header/footer",
          "Responsive framework",
          "API service structure",
          "Environment configuration",
          "Qualification selection",
          "Stream selection",
          "Dynamic selection",
          "Course listing",
          "Course categories",
          "Course details",
          "Course selection",
          "College listing",
          "Top colleges",
          "College details",
          "College search/filter",
          "Enquiry form",
          "Step-by-step flow",
          "Validation",
          "Submission"
        ],
        backend: [
          "Qualification master API",
          "Stream master API",
          "Data relationships",
          "Student enquiry data storage",
          "Validation",
          "Enquiry status foundation"
        ],
        api: [
          "Qualification master API",
          "Stream master API",
          "Course master API",
          "Course filtering API",
          "Stream-course mapping API",
          "College master API",
          "College details API",
          "Course/college mapping API",
          "Enquiry API"
        ],
        database: [
          "Data relationships",
          "Student enquiry data storage"
        ]
      },
      deliverables: [
        "Functional Student Website core modules with Backend/API integration."
      ],
      notes: [
        "Distribution focus for this week: Student Website – Frontend + Backend + API."
      ]
    },
    {
      id: 4,
      code: "04",
      week: "Week 4",
      title: "Student Website Complete Development",
      daysLabel: "Day 16–20",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Student Website Complete Development",
      distributionFocus: "Student Website – Advanced Modules + Integration",
      objective:
        "Complete the Student Website: banner and content, general counselling, full college information, search, filter, and recommendation, then integrate frontend and backend and verify the site end to end.",
      modules: [
        "Banner & Content",
        "General Counselling",
        "College Information",
        "Search, Filter & Recommendation",
        "Student Website Integration"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 16",
          name: "Banner & Content Modules",
          groups: [
            { label: "Frontend", items: ["Banner slider", "Announcement sections", "Campaign/scholarship sections"] },
            { label: "Backend/API", items: ["Banner/content API", "Admin-managed content structure"] }
          ]
        },
        {
          n: "02",
          day: "Day 17",
          name: "General Counselling",
          groups: [
            { label: "Frontend", items: ["Counselling request flow", "Guidance form", "Counselling enquiry"] },
            { label: "Backend/API", items: ["Counselling request API", "Data storage", "Status handling"] }
          ]
        },
        {
          n: "03",
          day: "Day 18",
          name: "College Information",
          groups: [
            {
              label: "Frontend",
              items: [
                "Complete college information",
                "Courses",
                "Fees",
                "Seats",
                "Scholarships",
                "College-related information"
              ]
            },
            { label: "Backend/API", items: ["College detail APIs", "Related course APIs", "Scholarship data API"] }
          ]
        },
        {
          n: "04",
          day: "Day 19",
          name: "Search, Filter & Recommendation Flow",
          groups: [
            {
              label: "Frontend",
              items: ["Stream filters", "Course filters", "College filters", "Requirement-based college display"]
            },
            {
              label: "Backend/API",
              items: [
                "Filter APIs",
                "Recommendation/business-rule implementation based on finalized requirements"
              ]
            }
          ]
        },
        {
          n: "05",
          day: "Day 20",
          name: "Student Website Integration",
          items: [
            "Complete frontend/backend integration",
            "API error handling",
            "Form validation",
            "Loading states",
            "Empty states",
            "Success/error messages",
            "Responsive corrections",
            "End-to-end development verification"
          ]
        }
      ],
      technical: {
        frontend: [
          "Banner slider",
          "Announcement sections",
          "Campaign/scholarship sections",
          "Counselling request flow",
          "Guidance form",
          "Counselling enquiry",
          "Complete college information",
          "Courses",
          "Fees",
          "Seats",
          "Scholarships",
          "College-related information",
          "Stream filters",
          "Course filters",
          "College filters",
          "Requirement-based college display",
          "Complete frontend/backend integration",
          "API error handling",
          "Form validation",
          "Loading states",
          "Empty states",
          "Success/error messages",
          "Responsive corrections"
        ],
        backend: [
          "Admin-managed content structure",
          "Data storage",
          "Status handling",
          "Recommendation/business-rule implementation based on finalized requirements"
        ],
        api: [
          "Banner/content API",
          "Counselling request API",
          "College detail APIs",
          "Related course APIs",
          "Scholarship data API",
          "Filter APIs"
        ],
        database: ["Admin-managed content structure", "Data storage"]
      },
      business: [
        "Recommendation/business-rule implementation based on finalized requirements"
      ],
      dependencies: [
        "Finalized requirements for recommendation / business-rule implementation"
      ],
      deliverables: ["Complete Student Website development."],
      notes: [
        "Distribution focus for this week: Student Website – Advanced Modules + Integration.",
        "Recommendation and business-rule implementation is based on finalized requirements. Those rules are not expanded beyond what the plan states."
      ]
    },
    {
      id: 5,
      code: "05",
      week: "Week 5",
      title: "Admin Panel Development",
      daysLabel: "Day 21–25",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Admin Panel Development",
      distributionFocus: "Admin Panel – Frontend + Backend + API",
      objective:
        "Build a functional Admin Panel: authentication and dashboard, College Master, Course & Filter Master, and enquiry management, then connect that panel with Student Website data.",
      modules: [
        "Admin Authentication & Dashboard",
        "College Master",
        "Course & Filter Master",
        "Enquiry Management",
        "Admin Integration"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 21",
          name: "Admin Authentication & Dashboard",
          groups: [
            { label: "Frontend", items: ["Admin login", "Dashboard", "Sidebar", "Navigation", "Summary cards"] },
            { label: "Backend/API", items: ["Admin authentication", "Session/token handling", "Dashboard summary API"] }
          ]
        },
        {
          n: "02",
          day: "Day 22",
          name: "College Master",
          groups: [
            {
              label: "Frontend",
              items: ["College listing", "Add college", "Edit college", "View college", "Status management"]
            },
            { label: "Backend/API", items: ["College CRUD APIs", "College validation", "College status API"] }
          ],
          noteTitle: "College data structure to support",
          notes: [
            "Basic information",
            "Location",
            "Courses",
            "Fees",
            "Seats",
            "Scholarship details",
            "Other finalized college information"
          ]
        },
        {
          n: "03",
          day: "Day 23",
          name: "Course & Filter Master",
          groups: [
            {
              label: "Frontend",
              items: [
                "Stream management",
                "Course management",
                "Specialization",
                "Filter management",
                "Mapping screens"
              ]
            },
            {
              label: "Backend/API",
              items: ["Stream APIs", "Course APIs", "Specialization APIs", "Filter APIs", "Mapping APIs"]
            }
          ]
        },
        {
          n: "04",
          day: "Day 24",
          name: "Enquiry Management",
          groups: [
            {
              label: "Frontend",
              items: ["Enquiry listing", "Enquiry details", "Search", "Filters", "Status", "Student information"]
            },
            {
              label: "Backend/API",
              items: ["Enquiry listing API", "Enquiry details API", "Search/filter API", "Enquiry status API"]
            }
          ]
        },
        {
          n: "05",
          day: "Day 25",
          name: "Admin Integration",
          items: [
            "Student Website ↔ Admin Panel",
            "College data integration",
            "Course data integration",
            "Enquiry data integration",
            "Dashboard data integration",
            "CRUD validation",
            "API error handling",
            "Admin workflow completion"
          ]
        }
      ],
      technical: {
        frontend: [
          "Admin login",
          "Dashboard",
          "Sidebar",
          "Navigation",
          "Summary cards",
          "College listing",
          "Add college",
          "Edit college",
          "View college",
          "Status management",
          "Stream management",
          "Course management",
          "Specialization",
          "Filter management",
          "Mapping screens",
          "Enquiry listing",
          "Enquiry details",
          "Search",
          "Filters",
          "Status",
          "Student information"
        ],
        backend: [
          "Admin authentication",
          "Session/token handling",
          "College validation",
          "CRUD validation"
        ],
        api: [
          "Dashboard summary API",
          "College CRUD APIs",
          "College status API",
          "Stream APIs",
          "Course APIs",
          "Specialization APIs",
          "Filter APIs",
          "Mapping APIs",
          "Enquiry listing API",
          "Enquiry details API",
          "Search/filter API",
          "Enquiry status API"
        ],
        database: [
          "College data structure to support: Basic information, Location, Courses, Fees, Seats, Scholarship details, Other finalized college information"
        ]
      },
      integration: [
        "Student Website ↔ Admin Panel",
        "College data integration",
        "Course data integration",
        "Enquiry data integration",
        "Dashboard data integration"
      ],
      deliverables: [
        "Functional Admin Panel with core master and enquiry management."
      ],
      notes: [
        "Distribution focus for this week: Admin Panel – Frontend + Backend + API.",
        "“Other finalized college information” is retained as stated. Additional college fields are not assumed."
      ]
    },
    {
      id: 6,
      code: "06",
      week: "Week 6",
      title: "Live Office + Lead Routing",
      daysLabel: "Day 26–30",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Live Office + Lead Routing",
      distributionFocus: "Live Office + Lead Routing",
      objective:
        "Build the Live Office screen and the agreed lead-routing flow, including counsellor handling and college assignment. Live data fetch and automated live update are researched and confirmed before implementation, and are not a confirmed development commitment.",
      modules: ["Live Office Screen", "Enquiry Handling & Counsellor Flow", "Lead Routing"],
      tasks: [
        {
          n: "01",
          day: "Day 26",
          name: "Live Office Screen UI",
          groups: [
            {
              label: "Frontend",
              items: [
                "Full-screen Live Office layout",
                "Today's enquiry count",
                "Website enquiry count",
                "Instagram Ads enquiry count",
                "Facebook Ads enquiry count",
                "Live indicator",
                "Source-wise enquiry display",
                "Responsive/full-screen presentation layout"
              ]
            },
            {
              label: "Backend/API",
              items: [
                "Identify required Live Office APIs",
                "Enquiry aggregation API",
                "Source-wise enquiry API"
              ]
            }
          ]
        },
        {
          n: "02",
          day: "Day 27",
          name: "Live Office Data Fetch & Auto Live Update",
          status: "TECHNICAL FEASIBILITY",
          feasibility: true,
          items: [
            "Data source availability",
            "Whether required data can be fetched through API",
            "Instagram/Facebook/Website enquiry data availability",
            "API access/permissions",
            "Real-time vs periodic data fetching",
            "WebSocket / polling / webhook feasibility",
            "Automatic live update possibility",
            "Third-party API limitations",
            "Authentication/API credentials required"
          ]
        },
        {
          n: "03",
          day: "Day 28",
          name: "Enquiry Handling & Counsellor Flow",
          groups: [
            {
              label: "Frontend",
              items: [
                "Incoming enquiry view",
                "Student details",
                "Course interest",
                "Contact details",
                "Enquiry source",
                "Counsellor action",
                "Enquiry status"
              ]
            },
            {
              label: "Backend/API",
              items: [
                "Enquiry assignment API",
                "Counsellor action API",
                "Status update API",
                "Follow-up data handling"
              ]
            }
          ]
        },
        {
          n: "04",
          day: "Day 29",
          name: "Lead Routing",
          flow: [
            "Student Enquiry",
            "Best Academy – First Priority",
            "Counsellor Contacts Student",
            "Interest & Eligibility Check",
            "Suitable College Identified",
            "College Assignment",
            "College Receives Enquiry"
          ],
          groups: [
            { label: "Frontend", items: ["Lead status", "Assignment", "Routing information", "Action controls"] },
            {
              label: "Backend/API",
              items: [
                "Lead routing API",
                "Priority logic",
                "Assignment logic",
                "Status transition logic",
                "Routing history"
              ]
            }
          ]
        },
        {
          n: "05",
          day: "Day 30",
          name: "Lead Routing Integration",
          items: [
            "Student enquiry → Lead creation",
            "Best Academy priority",
            "Counsellor handling",
            "College assignment",
            "Lead status update",
            "Admin visibility",
            "Live Office integration where technically supported",
            "Complete lead workflow integration"
          ]
        }
      ],
      technical: {
        frontend: [
          "Full-screen Live Office layout",
          "Today's enquiry count",
          "Website enquiry count",
          "Instagram Ads enquiry count",
          "Facebook Ads enquiry count",
          "Live indicator",
          "Source-wise enquiry display",
          "Responsive/full-screen presentation layout",
          "Incoming enquiry view",
          "Student details",
          "Course interest",
          "Contact details",
          "Enquiry source",
          "Counsellor action",
          "Enquiry status",
          "Lead status",
          "Assignment",
          "Routing information",
          "Action controls"
        ],
        backend: [
          "Identify required Live Office APIs",
          "Follow-up data handling",
          "Priority logic",
          "Assignment logic",
          "Status transition logic",
          "Routing history"
        ],
        api: [
          "Enquiry aggregation API",
          "Source-wise enquiry API",
          "Enquiry assignment API",
          "Counsellor action API",
          "Status update API",
          "Lead routing API"
        ]
      },
      business: [
        "Student Enquiry",
        "Best Academy – First Priority",
        "Counsellor Contacts Student",
        "Interest & Eligibility Check",
        "Suitable College Identified",
        "College Assignment",
        "College Receives Enquiry",
        "Best Academy priority",
        "Priority logic",
        "Assignment logic",
        "Status transition logic"
      ],
      integration: [
        "Student enquiry → Lead creation",
        "Admin visibility",
        "Live Office integration where technically supported",
        "Complete lead workflow integration"
      ],
      dependencies: [
        "Technical feasibility confirmation for Live Office data fetch and automated live update",
        "API availability, access permissions, third-party limitations, and authentication/API credentials for that live-update research"
      ],
      deliverables: [
        "Lead Routing module + Live Office core development, with live data/auto-update subject to technical feasibility confirmation."
      ],
      notes: [
        "Within this week, one item only is marked TBD / Research Required: Day 27, Live Office Data Fetch & Auto Live Update.",
        "Day 27 is not shown as a confirmed development commitment.",
        "Live Office integration on Day 30 is included only where technically supported."
      ]
    },
    {
      id: 7,
      code: "07",
      week: "Week 7",
      title: "Complete Backend, API & System Integration",
      daysLabel: "Day 31–35",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Complete Backend, API & System Integration",
      distributionFocus: "Backend + API + Complete Integration",
      objective:
        "Complete the remaining backend and API work, apply the stated business rules, integrate the modules, handle the listed edge cases, and prepare a development-complete build for the dedicated QA phase.",
      modules: [
        "Backend Completion",
        "API Integration",
        "Business Rules",
        "Integration & Edge Cases",
        "Development Completion Review"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 31",
          name: "Backend Completion",
          items: [
            "Complete pending APIs",
            "Database relationships",
            "Business logic",
            "Validation",
            "Error handling",
            "Status management"
          ]
        },
        {
          n: "02",
          day: "Day 32",
          name: "API Integration",
          items: [
            "Student APIs",
            "Admin APIs",
            "College APIs",
            "Course APIs",
            "Enquiry APIs",
            "Lead APIs",
            "Dashboard APIs",
            "Frontend/API integration"
          ]
        },
        {
          n: "03",
          day: "Day 33",
          name: "Business Rules",
          items: [
            "Qualification/course rules",
            "College matching rules",
            "Enquiry rules",
            "Lead priority",
            "College assignment",
            "Status transitions",
            "Duplicate/invalid data handling"
          ]
        },
        {
          n: "04",
          day: "Day 34",
          name: "Integration & Edge Cases",
          items: [
            "Complete module integration",
            "API response handling",
            "Empty data handling",
            "Invalid input handling",
            "Permission handling",
            "Session/authentication handling",
            "Data consistency"
          ]
        },
        {
          n: "05",
          day: "Day 35",
          name: "Development Completion Review",
          items: [
            "Complete module walkthrough",
            "Pending development identification",
            "UI/API mismatch correction",
            "Final development fixes",
            "Prepare build for dedicated QA phase"
          ]
        }
      ],
      technical: {
        backend: [
          "Complete pending APIs",
          "Database relationships",
          "Business logic",
          "Validation",
          "Error handling",
          "Status management",
          "Duplicate/invalid data handling",
          "Permission handling",
          "Session/authentication handling",
          "Data consistency"
        ],
        api: [
          "Student APIs",
          "Admin APIs",
          "College APIs",
          "Course APIs",
          "Enquiry APIs",
          "Lead APIs",
          "Dashboard APIs",
          "Frontend/API integration",
          "API response handling"
        ],
        database: ["Database relationships", "Data consistency"]
      },
      business: [
        "Qualification/course rules",
        "College matching rules",
        "Enquiry rules",
        "Lead priority",
        "College assignment",
        "Status transitions",
        "Duplicate/invalid data handling"
      ],
      integration: [
        "Complete module integration",
        "Frontend/API integration"
      ],
      deliverables: ["Development-complete build."],
      notes: [
        "Remaining backend and API work is completed in this sprint.",
        "Distribution focus for this week: Backend + API + Complete Integration.",
        "Day 35 prepares the build for the dedicated QA phase. The QA phase itself stays outside the 40 development days."
      ]
    },
    {
      id: 8,
      code: "08",
      week: "Week 8",
      title: "Final Development Closure & Deployment Preparation",
      daysLabel: "Day 36–40",
      duration: "5 Working Days",
      status: "PLANNED",
      focus: "Final Development Closure & Deployment Preparation",
      distributionFocus: "Final Development + Deployment Preparation",
      objective:
        "Close remaining development, finish integration, prepare deployment, and hand the development build to QA. This sprint does not include the testing phase.",
      modules: [
        "Final UI & Functional Completion",
        "Final Backend/API Completion",
        "Integration Completion",
        "Deployment Preparation",
        "Development Handover to QA"
      ],
      tasks: [
        {
          n: "01",
          day: "Day 36",
          name: "Final UI & Functional Completion",
          items: [
            "Pending UI corrections",
            "Missing screen completion",
            "Responsive layout completion",
            "Common component consistency",
            "Final frontend development"
          ]
        },
        {
          n: "02",
          day: "Day 37",
          name: "Final Backend/API Completion",
          items: [
            "Pending API completion",
            "API response optimization",
            "Validation completion",
            "Database finalization",
            "Business logic completion"
          ]
        },
        {
          n: "03",
          day: "Day 38",
          name: "Integration Completion",
          items: [
            "Final frontend/backend integration",
            "Admin ↔ Website",
            "Enquiry ↔ Lead Routing",
            "College ↔ Course",
            "Dashboard ↔ Data",
            "Notification/integration points where applicable"
          ]
        },
        {
          n: "04",
          day: "Day 39",
          name: "Deployment Preparation",
          items: [
            "Production environment setup",
            "Environment variables",
            "Database configuration",
            "API configuration",
            "Domain/server configuration",
            "Build configuration",
            "Deployment readiness"
          ]
        },
        {
          n: "05",
          day: "Day 40",
          name: "Development Handover to QA",
          items: [
            "Final development build",
            "Development checklist",
            "API documentation",
            "Module completion checklist",
            "Known technical dependencies",
            "QA handover",
            "Testing environment preparation"
          ]
        }
      ],
      technical: {
        frontend: [
          "Pending UI corrections",
          "Missing screen completion",
          "Responsive layout completion",
          "Common component consistency",
          "Final frontend development",
          "Final frontend/backend integration"
        ],
        backend: [
          "Pending API completion",
          "API response optimization",
          "Validation completion",
          "Database finalization",
          "Business logic completion"
        ],
        api: ["Pending API completion", "API response optimization", "API configuration", "API documentation"],
        database: ["Database finalization", "Database configuration"]
      },
      integration: [
        "Final frontend/backend integration",
        "Admin ↔ Website",
        "Enquiry ↔ Lead Routing",
        "College ↔ Course",
        "Dashboard ↔ Data",
        "Notification/integration points where applicable"
      ],
      dependencies: [
        "Known technical dependencies, recorded at handover",
        "Notification/integration points where applicable"
      ],
      deliverables: ["Development Complete → QA Handover Build"],
      notes: [
        "Because testing has its own 10-working-day period, Week 8 contains development closure and deployment preparation only. Testing tasks are not part of this sprint.",
        "Distribution focus for this week: Final Development + Deployment Preparation."
      ]
    }
  ],

  qa: {
    title: "QA – 10 Working Days",
    separate: true,
    note: "This phase is shown separately, beyond the 40 development days.",
    rows: [
      { days: "Day 1–2", activity: "Module-wise Functional Testing" },
      { days: "Day 3–4", activity: "Student Website + Admin Integration Testing" },
      { days: "Day 5", activity: "Lead Routing & Enquiry Flow Testing" },
      { days: "Day 6", activity: "Live Office / API / Data Flow Testing" },
      { days: "Day 7", activity: "Responsive & Cross-Browser Testing" },
      { days: "Day 8", activity: "Regression Testing + Bug Verification" },
      { days: "Day 9", activity: "Client/UAT Support + Fix Verification" },
      { days: "Day 10", activity: "Final Regression + QA Sign-off" }
    ]
  },

  feasibility: {
    status: "TECHNICAL FEASIBILITY",
    sprint: "Sprint 06 · Week 6 · Day 27",
    title: "Live Office – Data Fetch & Automated Live Update",
    requirement:
      "Live Office Data Fetch & Auto Live Update: fetching live enquiry data from the required sources and automatically updating the Live Office screen.",
    statement:
      "The technical feasibility of fetching live enquiry data from the required sources and automatically updating the Live Office screen will be researched and confirmed before implementation. The final approach will depend on API availability, access permissions, third-party limitations and technical feasibility.",
    why: "This requirement has not yet been researched and confirmed. It is the one Week 6 item marked TBD / Research Required.",
    validation: [
      "Data source availability",
      "Whether required data can be fetched through API",
      "Instagram/Facebook/Website enquiry data availability",
      "API access/permissions",
      "Real-time vs periodic data fetching",
      "WebSocket / polling / webhook feasibility",
      "Automatic live update possibility",
      "Third-party API limitations",
      "Authentication/API credentials required"
    ],
    implementation: "Subject to technical feasibility confirmation.",
    notACommitment: true
  },

  modules: [
    {
      id: "research",
      name: "Research & Technical Analysis",
      purpose:
        "Establish the Phase 1 technical understanding before build: requirements, journeys, admin and data structure, APIs, database planning, and lead-routing feasibility.",
      features: [
        "Complete application and requirement study",
        "Student journey and business flow",
        "Admin and data structure analysis",
        "Backend, API, and database analysis",
        "Lead routing and technical feasibility review",
        "Final development task breakdown"
      ],
      subModules: [
        "Student Website analysis",
        "Admin Panel analysis",
        "Live Office Screen analysis",
        "Lead Routing analysis",
        "College Master requirements",
        "Course & Filter Master",
        "Enquiry data structure"
      ],
      sprints: ["Sprint 01"],
      frontend: [],
      backend: [
        "Authentication requirements",
        "Third-party dependency analysis"
      ],
      api: [
        "API requirement identification",
        "Student APIs",
        "College APIs",
        "Course APIs",
        "Enquiry APIs",
        "Lead routing APIs",
        "Admin APIs"
      ],
      database: ["Database entity identification", "Table/relationship planning"],
      integration: ["Third-party dependency analysis"],
      business: [
        "Qualification selection flow",
        "Stream selection",
        "Course selection",
        "College discovery",
        "College details",
        "Enquiry flow",
        "General counselling flow",
        "Student data collection requirements",
        "Best Academy first-priority flow",
        "Counsellor handling flow",
        "College assignment flow",
        "Lead status requirements",
        "Routing conditions",
        "Tracking requirements"
      ],
      dependencies: [
        "Complete Phase 1 requirements",
        "Identify technically uncertain requirements"
      ],
      deliverables: [
        "Finalized technical understanding, architecture plan, API list, database plan and development breakdown."
      ]
    },
    {
      id: "design-system",
      name: "Design System & Frontend Foundation",
      purpose: "Provide the Phase 1 UI foundation and the reusable components used by the Student Website, Admin Panel, Live Office, and Lead Routing screens.",
      features: [
        "Project UI foundation",
        "Typography",
        "Color system",
        "Buttons",
        "Cards",
        "Form components",
        "Input components",
        "Dropdowns",
        "Modal components",
        "Table components",
        "Common responsive components",
        "Final UI consistency review"
      ],
      subModules: ["Design System", "Common responsive components"],
      sprints: ["Sprint 02", "Sprint 03", "Sprint 08"],
      frontend: [
        "Project UI foundation",
        "Typography",
        "Color system",
        "Buttons",
        "Cards",
        "Form components",
        "Input components",
        "Dropdowns",
        "Modal components",
        "Table components",
        "Common responsive components",
        "Frontend project architecture",
        "Routing",
        "Reusable components",
        "Layout",
        "Header/footer",
        "Responsive framework",
        "API service structure",
        "Environment configuration",
        "Common component consistency",
        "Final frontend development"
      ],
      backend: [],
      api: ["API service structure"],
      database: [],
      integration: [],
      business: [],
      dependencies: [],
      deliverables: [
        "Complete Phase 1 UI/UX and reusable frontend component foundation."
      ]
    },
    {
      id: "student-website",
      name: "Student Website",
      purpose:
        "The student-facing site: homepage, qualification, stream, and course selection, navigation, and the responsive layouts that carry the discovery, enquiry, content, and counselling modules.",
      features: [
        "Homepage",
        "Banner slider",
        "Qualification selection",
        "Stream selection",
        "Course selection",
        "Navigation flow",
        "Responsive layouts"
      ],
      subModules: [
        "Homepage",
        "Qualification selection",
        "Stream selection",
        "Course selection",
        "Navigation flow"
      ],
      sprints: ["Sprint 02", "Sprint 03", "Sprint 04"],
      frontend: [
        "Homepage",
        "Banner slider",
        "Qualification selection",
        "Stream selection",
        "Course selection",
        "Navigation flow",
        "Responsive layouts",
        "Responsive corrections",
        "End-to-end development verification"
      ],
      backend: [],
      api: [],
      database: [],
      integration: ["Complete frontend/backend integration"],
      business: ["Understand complete user journey"],
      dependencies: ["Study complete Phase 1 requirements"],
      deliverables: ["Complete Student Website development."]
    },
    {
      id: "qualification-stream",
      name: "Qualification & Stream",
      purpose: "Let a student select qualification and stream, including dynamic selection, backed by qualification and stream master APIs and their data relationships.",
      features: ["Qualification selection", "Stream selection", "Dynamic selection"],
      subModules: ["Qualification selection flow", "Stream selection"],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 03"],
      frontend: ["Qualification selection", "Stream selection", "Dynamic selection"],
      backend: ["Qualification master API", "Stream master API", "Data relationships"],
      api: ["Qualification master API", "Stream master API"],
      database: ["Data relationships"],
      integration: [],
      business: ["Qualification selection flow", "Stream selection", "Qualification/course rules"],
      dependencies: [],
      deliverables: ["Functional Student Website core modules with Backend/API integration."]
    },
    {
      id: "course-explorer",
      name: "Course Explorer",
      purpose: "Present courses for discovery and selection, including categories, details, filtering, and stream-course mapping.",
      features: ["Course listing", "Course categories", "Course details", "Course selection", "Course Explorer"],
      subModules: ["Course listing", "Course categories", "Course details", "Course selection"],
      sprints: ["Sprint 02", "Sprint 03", "Sprint 05"],
      frontend: ["Course Explorer", "Course listing", "Course categories", "Course details", "Course selection", "Course management"],
      backend: ["Course master API", "Course filtering API", "Stream-course mapping API"],
      api: ["Course master API", "Course filtering API", "Stream-course mapping API", "Course APIs", "Related course APIs"],
      database: ["Stream-course mapping", "College/course relationship"],
      integration: ["Course data integration", "College ↔ Course"],
      business: ["Course selection", "Qualification/course rules"],
      dependencies: [],
      deliverables: ["Functional Student Website core modules with Backend/API integration."]
    },
    {
      id: "college",
      name: "College Discovery & College Information",
      purpose:
        "Help a student find colleges and read college information, including top colleges, listing, details, search and filter, courses, fees, seats, scholarships, and related college information.",
      features: [
        "Top 10 Colleges",
        "College listing",
        "Top colleges",
        "College details",
        "College search/filter",
        "Search/filter interface",
        "Complete college information",
        "Courses",
        "Fees",
        "Seats",
        "Scholarships",
        "Scholarship information section",
        "College-related information"
      ],
      subModules: [
        "College discovery",
        "College details",
        "Top 10 Colleges",
        "Scholarship information",
        "Fees/seats and related college data"
      ],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 03", "Sprint 04", "Sprint 05"],
      frontend: [
        "Top 10 Colleges",
        "College listing",
        "Top colleges",
        "College details",
        "College search/filter",
        "Search/filter interface",
        "Scholarship information section",
        "Complete college information",
        "Courses",
        "Fees",
        "Seats",
        "Scholarships",
        "College-related information"
      ],
      backend: [
        "College master API",
        "College details API",
        "Course/college mapping API",
        "College detail APIs",
        "Related course APIs",
        "Scholarship data API"
      ],
      api: [
        "College master API",
        "College details API",
        "Course/college mapping API",
        "College detail APIs",
        "Related course APIs",
        "Scholarship data API",
        "College APIs",
        "College CRUD APIs",
        "College status API"
      ],
      database: [
        "College/course relationship",
        "Scholarship information",
        "Fees/seats and related college data",
        "Basic information",
        "Location",
        "Courses",
        "Fees",
        "Seats",
        "Scholarship details",
        "Other finalized college information"
      ],
      integration: ["College data integration", "College ↔ Course", "Course/college mapping API"],
      business: ["College discovery", "College details", "College matching rules"],
      dependencies: ["Other finalized college information"],
      deliverables: ["Complete Student Website development."]
    },
    {
      id: "enquiry",
      name: "Student Enquiry",
      purpose:
        "Collect a student enquiry in steps, store it, validate it, and give it a status foundation that later admin, counsellor, and lead-routing work can use.",
      features: [
        "Step-by-step enquiry form",
        "Student information",
        "Qualification/marks",
        "Course interest",
        "Contact details",
        "Enquiry confirmation",
        "Validation/error states",
        "Enquiry form",
        "Step-by-step flow",
        "Validation",
        "Submission"
      ],
      subModules: [
        "Student information",
        "Qualification/marks",
        "Course interest",
        "Contact details",
        "Enquiry confirmation"
      ],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 03", "Sprint 05", "Sprint 06"],
      frontend: [
        "Step-by-step enquiry form",
        "Student information",
        "Qualification/marks",
        "Course interest",
        "Contact details",
        "Enquiry confirmation",
        "Validation/error states",
        "Enquiry form",
        "Step-by-step flow",
        "Validation",
        "Submission",
        "Form validation"
      ],
      backend: [
        "Enquiry API",
        "Student enquiry data storage",
        "Validation",
        "Enquiry status foundation",
        "Enquiry data structure"
      ],
      api: ["Enquiry API", "Enquiry APIs"],
      database: ["Student enquiry data storage", "Enquiry data structure", "Enquiry status foundation"],
      integration: ["Student enquiry → Lead creation", "Enquiry data integration", "Enquiry ↔ Lead Routing"],
      business: ["Enquiry flow", "Enquiry rules", "Student data collection requirements"],
      dependencies: ["Student data collection requirements"],
      deliverables: ["Functional Student Website core modules with Backend/API integration."]
    },
    {
      id: "content",
      name: "Banner, Announcements & Campaign / Scholarship Content",
      purpose: "Show banner, announcement, and campaign/scholarship content on the Student Website, with an admin-managed content structure.",
      features: ["Banner slider", "Announcement sections", "Campaign/scholarship sections"],
      subModules: ["Banner slider", "Announcement sections", "Campaign/scholarship sections"],
      sprints: ["Sprint 02", "Sprint 04"],
      frontend: ["Banner slider", "Announcement sections", "Campaign/scholarship sections"],
      backend: ["Admin-managed content structure"],
      api: ["Banner/content API"],
      database: ["Admin-managed content structure"],
      integration: [],
      business: [],
      dependencies: [],
      deliverables: ["Complete Student Website development."]
    },
    {
      id: "counselling",
      name: "General Counselling",
      purpose: "Let a student request general counselling through a guidance form and counselling enquiry, with storage and status handling.",
      features: ["General counselling UI", "Counselling request flow", "Guidance form", "Counselling enquiry"],
      subModules: ["Counselling request flow", "Guidance form", "Counselling enquiry"],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 04"],
      frontend: ["General counselling UI", "Counselling request flow", "Guidance form", "Counselling enquiry"],
      backend: ["Counselling request API", "Data storage", "Status handling"],
      api: ["Counselling request API"],
      database: ["Data storage"],
      integration: [],
      business: ["General counselling flow", "Status handling"],
      dependencies: [],
      deliverables: ["Complete Student Website development."]
    },
    {
      id: "search",
      name: "Search, Filter & Recommendation",
      purpose:
        "Filter streams, courses, and colleges, and show colleges based on requirements. Recommendation and business rules are implemented from finalized requirements.",
      features: [
        "Search/filter interface",
        "Stream filters",
        "Course filters",
        "College filters",
        "Requirement-based college display",
        "College search/filter"
      ],
      subModules: ["Stream filters", "Course filters", "College filters", "Requirement-based college display"],
      sprints: ["Sprint 02", "Sprint 03", "Sprint 04", "Sprint 05"],
      frontend: [
        "Search/filter interface",
        "Stream filters",
        "Course filters",
        "College filters",
        "Requirement-based college display",
        "College search/filter"
      ],
      backend: [
        "Filter APIs",
        "Recommendation/business-rule implementation based on finalized requirements"
      ],
      api: ["Filter APIs", "Course filtering API", "Search/filter API"],
      database: [],
      integration: [],
      business: ["Recommendation/business-rule implementation based on finalized requirements"],
      dependencies: ["Finalized requirements for recommendation / business-rule implementation"],
      deliverables: ["Complete Student Website development."]
    },
    {
      id: "admin-auth",
      name: "Admin Authentication & Dashboard",
      purpose: "Give administrators a login, a dashboard with summary cards, sidebar navigation, and the related authentication, session/token, and summary API.",
      features: ["Admin login", "Dashboard", "Sidebar", "Navigation", "Summary cards", "Admin Dashboard UI"],
      subModules: ["Admin login", "Dashboard", "Sidebar", "Summary cards"],
      sprints: ["Sprint 02", "Sprint 05", "Sprint 07"],
      frontend: ["Admin Dashboard UI", "Admin login", "Dashboard", "Sidebar", "Navigation", "Summary cards"],
      backend: ["Admin authentication", "Session/token handling", "Session/authentication handling", "Permission handling"],
      api: ["Dashboard summary API", "Dashboard APIs", "Admin APIs"],
      database: [],
      integration: ["Dashboard data integration", "Dashboard ↔ Data"],
      business: [],
      dependencies: ["Authentication requirements"],
      deliverables: ["Functional Admin Panel with core master and enquiry management."]
    },
    {
      id: "college-master",
      name: "College Master",
      purpose: "Let administrators list, add, edit, view, and manage the status of colleges, using the college data structure described in the plan.",
      features: [
        "College listing",
        "Add college",
        "Edit college",
        "View college",
        "Status management",
        "College Master UI"
      ],
      subModules: [
        "Basic information",
        "Location",
        "Courses",
        "Fees",
        "Seats",
        "Scholarship details",
        "Other finalized college information"
      ],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 05"],
      frontend: ["College Master UI", "College listing", "Add college", "Edit college", "View college", "Status management"],
      backend: ["College CRUD APIs", "College validation", "College status API"],
      api: ["College CRUD APIs", "College status API", "College master API", "College details API"],
      database: [
        "Basic information",
        "Location",
        "Courses",
        "Fees",
        "Seats",
        "Scholarship details",
        "Other finalized college information"
      ],
      integration: ["College data integration"],
      business: ["College validation", "Status management"],
      dependencies: ["Other finalized college information", "College Master requirements"],
      deliverables: ["Functional Admin Panel with core master and enquiry management."]
    },
    {
      id: "course-filter-master",
      name: "Course & Filter Master",
      purpose: "Let administrators manage streams, courses, specializations, and filters, and maintain the mapping screens and mapping APIs.",
      features: [
        "Stream management",
        "Course management",
        "Specialization",
        "Filter management",
        "Mapping screens",
        "Course & Filter Master UI"
      ],
      subModules: ["Stream management", "Course management", "Specialization", "Filter management", "Mapping screens"],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 05"],
      frontend: [
        "Course & Filter Master UI",
        "Stream management",
        "Course management",
        "Specialization",
        "Filter management",
        "Mapping screens"
      ],
      backend: ["Stream APIs", "Course APIs", "Specialization APIs", "Filter APIs", "Mapping APIs"],
      api: ["Stream APIs", "Course APIs", "Specialization APIs", "Filter APIs", "Mapping APIs"],
      database: ["College/course relationship", "Data relationships"],
      integration: ["Course data integration", "Mapping APIs"],
      business: [],
      dependencies: ["Course & Filter Master requirements from Week 1 analysis"],
      deliverables: ["Functional Admin Panel with core master and enquiry management."]
    },
    {
      id: "enquiry-admin",
      name: "Enquiry Management",
      purpose: "Let administrators list and open enquiries, search and filter them, see status and student information, and update enquiry status.",
      features: ["Enquiry listing", "Enquiry details", "Search", "Filters", "Status", "Student information"],
      subModules: ["Enquiry listing", "Enquiry details", "Search", "Filters", "Status", "Student information"],
      sprints: ["Sprint 05", "Sprint 06", "Sprint 07"],
      frontend: ["Enquiry listing", "Enquiry details", "Search", "Filters", "Status", "Student information"],
      backend: ["Enquiry listing API", "Enquiry details API", "Search/filter API", "Enquiry status API"],
      api: ["Enquiry listing API", "Enquiry details API", "Search/filter API", "Enquiry status API"],
      database: ["Enquiry data structure"],
      integration: ["Enquiry data integration"],
      business: ["Enquiry rules", "Enquiry status"],
      dependencies: [],
      deliverables: ["Functional Admin Panel with core master and enquiry management."]
    },
    {
      id: "admin-integration",
      name: "Admin Integration",
      purpose: "Connect the Student Website and the Admin Panel across college, course, enquiry, and dashboard data, and finish admin workflow validation and error handling.",
      features: [
        "Student Website ↔ Admin Panel",
        "College data integration",
        "Course data integration",
        "Enquiry data integration",
        "Dashboard data integration",
        "CRUD validation",
        "API error handling",
        "Admin workflow completion"
      ],
      subModules: [
        "College data integration",
        "Course data integration",
        "Enquiry data integration",
        "Dashboard data integration"
      ],
      sprints: ["Sprint 05", "Sprint 07", "Sprint 08"],
      frontend: [],
      backend: ["CRUD validation", "API error handling"],
      api: ["API error handling"],
      database: [],
      integration: [
        "Student Website ↔ Admin Panel",
        "College data integration",
        "Course data integration",
        "Enquiry data integration",
        "Dashboard data integration",
        "Admin ↔ Website",
        "Admin workflow completion"
      ],
      business: ["Admin management requirements"],
      dependencies: [],
      deliverables: ["Functional Admin Panel with core master and enquiry management."]
    },
    {
      id: "live-office",
      name: "Live Office Screen",
      purpose:
        "Present a full-screen Live Office view of enquiry counts by source, with a live indicator. Fetching live data and updating the screen automatically is subject to technical feasibility confirmation.",
      features: [
        "Full-screen Live Office layout",
        "Today's enquiry count",
        "Website enquiry count",
        "Instagram Ads enquiry count",
        "Facebook Ads enquiry count",
        "Live indicator",
        "Source-wise enquiry display",
        "Responsive/full-screen presentation layout",
        "Live Office Screen UI"
      ],
      subModules: [
        "Today's enquiry count",
        "Website enquiry count",
        "Instagram Ads enquiry count",
        "Facebook Ads enquiry count",
        "Live indicator",
        "Source-wise enquiry display"
      ],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 06"],
      frontend: [
        "Live Office Screen UI",
        "Full-screen Live Office layout",
        "Today's enquiry count",
        "Website enquiry count",
        "Instagram Ads enquiry count",
        "Facebook Ads enquiry count",
        "Live indicator",
        "Source-wise enquiry display",
        "Responsive/full-screen presentation layout"
      ],
      backend: ["Identify required Live Office APIs", "Enquiry aggregation API", "Source-wise enquiry API"],
      api: ["Identify required Live Office APIs", "Enquiry aggregation API", "Source-wise enquiry API"],
      database: [],
      integration: ["Live Office integration where technically supported"],
      business: [],
      dependencies: [
        "Data source availability",
        "API access/permissions",
        "Authentication/API credentials required",
        "Technical feasibility confirmation for automated live update"
      ],
      deliverables: [
        "Lead Routing module + Live Office core development, with live data/auto-update subject to technical feasibility confirmation."
      ]
    },
    {
      id: "lead-routing",
      name: "Lead Routing & Counsellor Handling",
      purpose:
        "Take a student enquiry through Best Academy first priority, counsellor contact, interest and eligibility, college identification, college assignment, and delivery of the enquiry to the college.",
      features: [
        "Incoming enquiry view",
        "Student details",
        "Course interest",
        "Contact details",
        "Enquiry source",
        "Counsellor action",
        "Enquiry status",
        "Lead status",
        "Assignment",
        "Routing information",
        "Action controls",
        "Lead Routing UI"
      ],
      subModules: [
        "Best Academy first-priority flow",
        "Counsellor handling flow",
        "College assignment flow",
        "Lead status",
        "Routing history"
      ],
      sprints: ["Sprint 01", "Sprint 02", "Sprint 06", "Sprint 07", "Sprint 08"],
      frontend: [
        "Lead Routing UI",
        "Incoming enquiry view",
        "Student details",
        "Course interest",
        "Contact details",
        "Enquiry source",
        "Counsellor action",
        "Enquiry status",
        "Lead status",
        "Assignment",
        "Routing information",
        "Action controls"
      ],
      backend: [
        "Enquiry assignment API",
        "Counsellor action API",
        "Status update API",
        "Follow-up data handling",
        "Lead routing API",
        "Priority logic",
        "Assignment logic",
        "Status transition logic",
        "Routing history"
      ],
      api: [
        "Lead routing APIs",
        "Enquiry assignment API",
        "Counsellor action API",
        "Status update API",
        "Lead routing API",
        "Lead APIs"
      ],
      database: ["Follow-up data handling", "Routing history", "Lead status requirements"],
      integration: [
        "Student enquiry → Lead creation",
        "Best Academy priority",
        "Counsellor handling",
        "College assignment",
        "Lead status update",
        "Admin visibility",
        "Live Office integration where technically supported",
        "Complete lead workflow integration",
        "Enquiry ↔ Lead Routing"
      ],
      business: [
        "Student Enquiry",
        "Best Academy – First Priority",
        "Counsellor Contacts Student",
        "Interest & Eligibility Check",
        "Suitable College Identified",
        "College Assignment",
        "College Receives Enquiry",
        "Lead priority",
        "Routing conditions",
        "Tracking requirements",
        "Status transition logic"
      ],
      dependencies: ["Lead status requirements", "Routing conditions", "Tracking requirements"],
      deliverables: [
        "Lead Routing module + Live Office core development, with live data/auto-update subject to technical feasibility confirmation."
      ]
    },
    {
      id: "platform",
      name: "Backend Completion, Integration & Deployment",
      purpose:
        "Finish pending APIs, database relationships, validation, business rules, and cross-module integration, then prepare deployment and hand the build to QA.",
      features: [
        "Complete pending APIs",
        "Database relationships",
        "Business logic",
        "Validation",
        "Error handling",
        "Status management",
        "Complete module integration",
        "Deployment preparation",
        "QA handover"
      ],
      subModules: [
        "Backend Completion",
        "API Integration",
        "Business Rules",
        "Integration & Edge Cases",
        "Deployment Preparation",
        "Development Handover to QA"
      ],
      sprints: ["Sprint 07", "Sprint 08"],
      frontend: [
        "Pending UI corrections",
        "Missing screen completion",
        "Responsive layout completion",
        "Common component consistency",
        "Final frontend development"
      ],
      backend: [
        "Complete pending APIs",
        "Database relationships",
        "Business logic",
        "Validation",
        "Error handling",
        "Status management",
        "Pending API completion",
        "Validation completion",
        "Database finalization",
        "Business logic completion"
      ],
      api: [
        "Student APIs",
        "Admin APIs",
        "College APIs",
        "Course APIs",
        "Enquiry APIs",
        "Lead APIs",
        "Dashboard APIs",
        "Frontend/API integration",
        "API response optimization",
        "API documentation",
        "API configuration"
      ],
      database: ["Database relationships", "Database finalization", "Database configuration", "Data consistency"],
      integration: [
        "Complete module integration",
        "Final frontend/backend integration",
        "Admin ↔ Website",
        "Enquiry ↔ Lead Routing",
        "College ↔ Course",
        "Dashboard ↔ Data",
        "Notification/integration points where applicable"
      ],
      business: [
        "Qualification/course rules",
        "College matching rules",
        "Enquiry rules",
        "Lead priority",
        "College assignment",
        "Status transitions",
        "Duplicate/invalid data handling"
      ],
      dependencies: [
        "Known technical dependencies",
        "Notification/integration points where applicable"
      ],
      deliverables: ["Development-complete build.", "Development Complete → QA Handover Build"]
    }
  ]
};

PLAN.leadFlow = [
  "Student Enquiry",
  "Best Academy – First Priority",
  "Counsellor Contacts Student",
  "Interest & Eligibility Check",
  "Suitable College Identified",
  "College Assignment",
  "College Receives Enquiry"
];

PLAN.studentJourney = [
  "Qualification selection flow",
  "Stream selection",
  "Course selection",
  "College discovery",
  "College details",
  "Enquiry flow"
];

PLAN.enquirySteps = [
  "Student information",
  "Qualification/marks",
  "Course interest",
  "Contact details",
  "Enquiry confirmation"
];

PLAN.completionFlow = [
  { sprint: "Sprint 1", label: "Research & Technical Analysis" },
  { sprint: "Sprint 2", label: "UI/UX Design & Frontend Foundation" },
  { sprint: "Sprint 3", label: "Student Website Frontend + Backend" },
  { sprint: "Sprint 4", label: "Student Website Complete Development" },
  { sprint: "Sprint 5", label: "Admin Panel Development" },
  { sprint: "Sprint 6", label: "Live Office + Lead Routing" },
  { sprint: "Sprint 7", label: "Complete Backend, API & System Integration" },
  { sprint: "Sprint 8", label: "Final Development Closure & Deployment Preparation" },
  { sprint: "QA", label: "Testing / QA — 10 Working Days" }
];

PLAN.apis = [
  { name: "Student APIs", purpose: "Student-side API requirements identified in analysis, then integrated in Week 7.", usedBy: "Student Website", module: "Student Website", flow: "Identified in Sprint 1. Integrated in Sprint 7.", dependency: "API requirement identification", status: "PLANNED", sprint: "Sprint 01, Sprint 07" },
  { name: "College APIs", purpose: "College API requirements identified in analysis and integrated in Week 7.", usedBy: "Student Website, Admin Panel", module: "College Discovery & College Master", flow: "Identified in Sprint 1. Integrated in Sprint 7.", dependency: "College Master requirements", status: "PLANNED", sprint: "Sprint 01, Sprint 07" },
  { name: "Course APIs", purpose: "Course API requirements identified in analysis, implemented for course management, and integrated in Week 7.", usedBy: "Student Website, Admin Panel", module: "Course Explorer, Course & Filter Master", flow: "Identified in Sprint 1. Course APIs in Sprint 5. Integrated in Sprint 7.", dependency: "Course & Filter Master", status: "PLANNED", sprint: "Sprint 01, Sprint 05, Sprint 07" },
  { name: "Enquiry APIs", purpose: "Enquiry API requirements identified in analysis and integrated in Week 7.", usedBy: "Student Website, Admin Panel, Lead Routing", module: "Student Enquiry", flow: "Identified in Sprint 1. Integrated in Sprint 7.", dependency: "Enquiry data structure", status: "PLANNED", sprint: "Sprint 01, Sprint 07" },
  { name: "Lead routing APIs", purpose: "Lead routing API requirements identified during backend analysis.", usedBy: "Lead Routing", module: "Lead Routing", flow: "Identified in Sprint 1. Implemented as Lead routing API in Sprint 6. Integrated as Lead APIs in Sprint 7.", dependency: "Lead status requirements, routing conditions", status: "PLANNED", sprint: "Sprint 01" },
  { name: "Admin APIs", purpose: "Admin API requirements identified in analysis and integrated in Week 7.", usedBy: "Admin Panel", module: "Admin Panel", flow: "Identified in Sprint 1. Integrated in Sprint 7.", dependency: "Admin management requirements", status: "PLANNED", sprint: "Sprint 01, Sprint 07" },
  { name: "Qualification master API", purpose: "Provide qualification master data for qualification selection.", usedBy: "Student Website", module: "Qualification & Stream", flow: "Student selects a qualification. The API supplies master data.", dependency: "Data relationships", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Stream master API", purpose: "Provide stream master data for stream selection.", usedBy: "Student Website", module: "Qualification & Stream", flow: "Student selects a stream. The API supplies master data.", dependency: "Data relationships", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Course master API", purpose: "Provide course master data for the Course Explorer.", usedBy: "Student Website", module: "Course Explorer", flow: "Course listing and course details read course master data.", dependency: "Stream-course mapping API", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Course filtering API", purpose: "Filter courses in the Course Explorer.", usedBy: "Student Website", module: "Course Explorer", flow: "Filter criteria are applied to course results.", dependency: "Course master API", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Stream-course mapping API", purpose: "Map streams to courses.", usedBy: "Student Website, Admin Panel", module: "Course Explorer, Course & Filter Master", flow: "Stream selection resolves related courses.", dependency: "Data relationships", status: "PLANNED", sprint: "Sprint 03" },
  { name: "College master API", purpose: "Provide college master data for college discovery.", usedBy: "Student Website", module: "College Discovery", flow: "College listing reads college master data.", dependency: "College Master requirements", status: "PLANNED", sprint: "Sprint 03" },
  { name: "College details API", purpose: "Provide college detail data for the college details view.", usedBy: "Student Website", module: "College Discovery", flow: "A selected college loads its details.", dependency: "College master API", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Course/college mapping API", purpose: "Map courses and colleges.", usedBy: "Student Website, Admin Panel", module: "College Discovery, College Master", flow: "Colleges are related to courses through the mapping.", dependency: "College/course relationship", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Enquiry API", purpose: "Accept and store a student enquiry.", usedBy: "Student Website", module: "Student Enquiry", flow: "The enquiry form submits to the Enquiry API, which stores the enquiry and establishes status.", dependency: "Student enquiry data storage, validation", status: "PLANNED", sprint: "Sprint 03" },
  { name: "Banner/content API", purpose: "Supply banner and content for the Student Website.", usedBy: "Student Website, Admin Panel", module: "Banner & Content", flow: "Admin-managed content is read by the Student Website.", dependency: "Admin-managed content structure", status: "PLANNED", sprint: "Sprint 04" },
  { name: "Counselling request API", purpose: "Accept a general counselling request.", usedBy: "Student Website", module: "General Counselling", flow: "The guidance form submits a counselling enquiry for storage and status handling.", dependency: "Data storage, status handling", status: "PLANNED", sprint: "Sprint 04" },
  { name: "College detail APIs", purpose: "Supply complete college information, including related college data.", usedBy: "Student Website", module: "College Information", flow: "College information screens read detail APIs.", dependency: "Related course APIs, Scholarship data API", status: "PLANNED", sprint: "Sprint 04" },
  { name: "Related course APIs", purpose: "Supply courses related to a college.", usedBy: "Student Website", module: "College Information", flow: "College information includes related courses.", dependency: "Course/college mapping API", status: "PLANNED", sprint: "Sprint 04" },
  { name: "Scholarship data API", purpose: "Supply scholarship data for college information.", usedBy: "Student Website", module: "College Information", flow: "Scholarship information is read with college information.", dependency: "Scholarship information", status: "PLANNED", sprint: "Sprint 04" },
  { name: "Filter APIs", purpose: "Support stream, course, and college filters.", usedBy: "Student Website", module: "Search, Filter & Recommendation", flow: "Filter selections request filtered college and course results.", dependency: "Finalized requirements for recommendation / business rules", status: "PLANNED", sprint: "Sprint 04" },
  { name: "Dashboard summary API", purpose: "Provide summary data for the admin dashboard cards.", usedBy: "Admin Panel", module: "Admin Authentication & Dashboard", flow: "The dashboard reads summary data after admin authentication.", dependency: "Admin authentication, session/token handling", status: "PLANNED", sprint: "Sprint 05" },
  { name: "College CRUD APIs", purpose: "Create, read, update, and manage college master records.", usedBy: "Admin Panel", module: "College Master", flow: "Add, edit, and view college use the CRUD APIs.", dependency: "College validation, college data structure", status: "PLANNED", sprint: "Sprint 05" },
  { name: "College status API", purpose: "Manage college status.", usedBy: "Admin Panel", module: "College Master", flow: "Status management updates college status.", dependency: "College CRUD APIs", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Stream APIs", purpose: "Manage streams in the Course & Filter Master.", usedBy: "Admin Panel", module: "Course & Filter Master", flow: "Stream management reads and updates stream data.", dependency: "Mapping APIs", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Specialization APIs", purpose: "Manage specialization data.", usedBy: "Admin Panel", module: "Course & Filter Master", flow: "Specialization management reads and updates specialization data.", dependency: "Course APIs", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Mapping APIs", purpose: "Support mapping screens for course and filter relationships.", usedBy: "Admin Panel", module: "Course & Filter Master", flow: "Mapping screens read and update mappings.", dependency: "Stream APIs, Course APIs, Filter APIs", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Enquiry listing API", purpose: "List enquiries in the Admin Panel.", usedBy: "Admin Panel", module: "Enquiry Management", flow: "The enquiry listing reads stored enquiries.", dependency: "Enquiry API", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Enquiry details API", purpose: "Provide one enquiry’s details, including student information.", usedBy: "Admin Panel", module: "Enquiry Management", flow: "An enquiry row opens its details.", dependency: "Enquiry listing API", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Search/filter API", purpose: "Search and filter enquiries in the Admin Panel.", usedBy: "Admin Panel", module: "Enquiry Management", flow: "Search and filter criteria narrow the enquiry list.", dependency: "Enquiry listing API", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Enquiry status API", purpose: "Read and update enquiry status.", usedBy: "Admin Panel", module: "Enquiry Management", flow: "Status changes are saved through the status API.", dependency: "Enquiry status foundation", status: "PLANNED", sprint: "Sprint 05" },
  { name: "Identify required Live Office APIs", purpose: "Identify the APIs the Live Office screen requires.", usedBy: "Live Office Screen", module: "Live Office Screen", flow: "Required Live Office APIs are identified before live data behaviour is confirmed.", dependency: "Day 27 technical feasibility", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Enquiry aggregation API", purpose: "Aggregate enquiry counts for the Live Office screen.", usedBy: "Live Office Screen", module: "Live Office Screen", flow: "Counts such as today’s enquiry count are aggregated for display.", dependency: "Source-wise enquiry API", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Source-wise enquiry API", purpose: "Provide enquiry data by source for the Live Office screen.", usedBy: "Live Office Screen", module: "Live Office Screen", flow: "Website, Instagram Ads, and Facebook Ads counts are shown source-wise.", dependency: "Enquiry aggregation API", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Live data fetch and automated live update", purpose: "Fetch live enquiry data from the required sources and update the Live Office screen automatically.", usedBy: "Live Office Screen", module: "Live Office Screen", flow: "To be researched. Not specified as polling, webhook, or WebSocket until feasibility is confirmed.", dependency: "API availability, access permissions, third-party limitations, credentials", status: "TECHNICAL FEASIBILITY", sprint: "Sprint 06 · Day 27" },
  { name: "Enquiry assignment API", purpose: "Assign an enquiry for counsellor handling.", usedBy: "Counsellor flow, Admin Panel", module: "Lead Routing", flow: "An incoming enquiry is assigned.", dependency: "Enquiry status", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Counsellor action API", purpose: "Record counsellor action on an enquiry.", usedBy: "Counsellor flow", module: "Lead Routing", flow: "Counsellor action is submitted and stored.", dependency: "Enquiry assignment API", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Status update API", purpose: "Update enquiry status from counsellor handling.", usedBy: "Counsellor flow", module: "Lead Routing", flow: "Status changes during counsellor handling are saved.", dependency: "Status transition logic", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Lead routing API", purpose: "Run lead routing, including priority, assignment, status transition, and routing history.", usedBy: "Lead Routing, Admin Panel", module: "Lead Routing", flow: "A student enquiry becomes a lead and moves through the agreed routing flow.", dependency: "Priority logic, assignment logic, status transition logic", status: "PLANNED", sprint: "Sprint 06" },
  { name: "Lead APIs", purpose: "Lead APIs included in Week 7 API integration.", usedBy: "Lead Routing, Admin Panel", module: "Lead Routing", flow: "Lead APIs are integrated with the frontend in Sprint 7.", dependency: "Lead routing API", status: "PLANNED", sprint: "Sprint 07" },
  { name: "Dashboard APIs", purpose: "Dashboard APIs included in Week 7 API integration.", usedBy: "Admin Panel", module: "Admin Dashboard", flow: "Dashboard APIs are integrated in Sprint 7.", dependency: "Dashboard summary API", status: "PLANNED", sprint: "Sprint 07" }
];

PLAN.database = {
  statement: "Database structure to be finalized during technical analysis. Sprint 1 identifies entities and plans tables and relationships. Sprint 7 completes database relationships. Sprint 8 finalizes the database. The rows below are the data subjects named in the plan. They are not a confirmed physical table list.",
  entities: [
    { name: "Qualification", purpose: "Qualification master for the selection flow.", relationships: "Data relationships with streams", crud: "Master data used by qualification selection. Admin stream/course management is separate.", usedBy: "Student Website", sprint: "Sprint 03" },
    { name: "Stream", purpose: "Stream master for stream selection and stream management.", relationships: "Data relationships; stream-course mapping", crud: "Stream master API; Stream APIs for management", usedBy: "Student Website, Admin Panel", sprint: "Sprint 03, Sprint 05" },
    { name: "Course", purpose: "Course master, course details, categories, and course management.", relationships: "Stream-course mapping; college/course relationship", crud: "Course master API; Course APIs", usedBy: "Student Website, Admin Panel", sprint: "Sprint 03, Sprint 05" },
    { name: "Specialization", purpose: "Specialization managed in the Course & Filter Master.", relationships: "Related through Course & Filter Master mappings", crud: "Specialization APIs", usedBy: "Admin Panel", sprint: "Sprint 05" },
    { name: "Filter", purpose: "Filters for discovery and for Course & Filter Master.", relationships: "Mapping APIs; filter APIs", crud: "Filter management; Filter APIs", usedBy: "Student Website, Admin Panel", sprint: "Sprint 04, Sprint 05" },
    { name: "College", purpose: "College master and college information.", relationships: "College/course relationship; course/college mapping", crud: "College master API, college details API, College CRUD APIs, college status API", usedBy: "Student Website, Admin Panel", sprint: "Sprint 03, Sprint 05" },
    { name: "College data structure", purpose: "Support the college information named in the plan.", relationships: "Courses, fees, seats, and scholarship details belong with the college", crud: "College CRUD and college information APIs", usedBy: "Admin Panel, Student Website", sprint: "Sprint 05", fields: ["Basic information", "Location", "Courses", "Fees", "Seats", "Scholarship details", "Other finalized college information"] },
    { name: "Scholarship", purpose: "Scholarship information and scholarship data.", relationships: "Related to college information", crud: "Scholarship data API", usedBy: "Student Website", sprint: "Sprint 04" },
    { name: "Fees and seats", purpose: "Fees/seats and related college data.", relationships: "Part of college information", crud: "Shown through college detail APIs and college master", usedBy: "Student Website, Admin Panel", sprint: "Sprint 01, Sprint 04, Sprint 05" },
    { name: "Enquiry", purpose: "Student enquiry data, enquiry data structure, and enquiry status.", relationships: "Becomes a lead; visible in admin and Live Office", crud: "Enquiry API, storage, listing, details, search/filter, status", usedBy: "Student Website, Admin Panel, Live Office, Lead Routing", sprint: "Sprint 03, Sprint 05, Sprint 06" },
    { name: "Counselling request", purpose: "General counselling request data.", relationships: "Separate counselling enquiry flow", crud: "Counselling request API, data storage, status handling", usedBy: "Student Website", sprint: "Sprint 04" },
    { name: "Banner / content", purpose: "Admin-managed content for banners, announcements, and campaign/scholarship sections.", relationships: "Managed for display on the Student Website", crud: "Banner/content API", usedBy: "Student Website, Admin Panel", sprint: "Sprint 04" },
    { name: "Lead and routing history", purpose: "Lead status, assignment, follow-up data, and routing history.", relationships: "Created from a student enquiry; assigned to a college", crud: "Lead routing API, status update, follow-up data handling", usedBy: "Lead Routing, Admin Panel", sprint: "Sprint 06" },
    { name: "Dashboard summary", purpose: "Summary data for admin dashboard cards.", relationships: "Reads across integrated admin data", crud: "Dashboard summary API", usedBy: "Admin Panel", sprint: "Sprint 05, Sprint 07" }
  ]
};

PLAN.integrations = [
  { name: "Student Website ↔ Admin Panel", purpose: "Connect website data with the Admin Panel.", module: "Admin Integration", requirement: "College, course, enquiry, and dashboard data integration", dependency: "Core modules from Sprints 3–5", status: "PLANNED" },
  { name: "College data integration", purpose: "Use the same college data on the website and in the Admin Panel.", module: "College Master, College Discovery", requirement: "Integration during Admin Integration and final integration", dependency: "College master and college information", status: "PLANNED" },
  { name: "Course data integration", purpose: "Use the same course data on the website and in the Admin Panel.", module: "Course Explorer, Course & Filter Master", requirement: "Integration during Admin Integration and College ↔ Course", dependency: "Course and mapping APIs", status: "PLANNED" },
  { name: "Enquiry data integration", purpose: "Carry student enquiries into admin management and lead routing.", module: "Enquiry, Admin, Lead Routing", requirement: "Enquiry data integration and Enquiry ↔ Lead Routing", dependency: "Enquiry storage and status", status: "PLANNED" },
  { name: "Dashboard data integration", purpose: "Feed the admin dashboard from live module data.", module: "Admin Dashboard", requirement: "Dashboard data integration and Dashboard ↔ Data", dependency: "Dashboard summary API", status: "PLANNED" },
  { name: "Admin ↔ Website", purpose: "Final integration point between the Admin Panel and the Student Website.", module: "Integration Completion", requirement: "Final frontend/backend integration", dependency: "Completed admin and website modules", status: "PLANNED" },
  { name: "Enquiry ↔ Lead Routing", purpose: "Connect enquiry handling with lead routing.", module: "Lead Routing", requirement: "Student enquiry → Lead creation and complete lead workflow integration", dependency: "Enquiry status and lead routing API", status: "PLANNED" },
  { name: "College ↔ Course", purpose: "Keep college and course relationships consistent.", module: "College, Course", requirement: "Mapping and final integration", dependency: "College/course relationship", status: "PLANNED" },
  { name: "Dashboard ↔ Data", purpose: "Connect dashboard summaries with underlying data.", module: "Admin Dashboard", requirement: "Final integration completion", dependency: "Dashboard APIs", status: "PLANNED" },
  { name: "Student enquiry → Lead creation", purpose: "Create a lead from a student enquiry.", module: "Lead Routing", requirement: "Lead routing integration", dependency: "Best Academy priority", status: "PLANNED" },
  { name: "Admin-managed content", purpose: "Let banner and content shown on the website be managed as admin content.", module: "Banner & Content", requirement: "Banner/content API and admin-managed content structure", dependency: "Content structure from Sprint 4", status: "PLANNED" },
  { name: "Live Office source display", purpose: "Show today’s, website, Instagram Ads, and Facebook Ads enquiry counts.", module: "Live Office Screen", requirement: "Enquiry aggregation API and source-wise enquiry API", dependency: "Identify required Live Office APIs", status: "PLANNED" },
  { name: "Live Office data fetch and automated live update", purpose: "Fetch live enquiry data and update the Live Office screen automatically.", module: "Live Office Screen", requirement: "Research and confirm before implementation", dependency: "API availability, access permissions, third-party limitations, credentials", status: "TECHNICAL FEASIBILITY" },
  { name: "Live Office integration where technically supported", purpose: "Include Live Office in the lead workflow only where the technical approach supports it.", module: "Lead Routing Integration", requirement: "Day 30 integration item", dependency: "Day 27 feasibility outcome", status: "TECHNICAL FEASIBILITY" },
  { name: "Notification/integration points where applicable", purpose: "Cover notification or integration points during final integration, where applicable.", module: "Integration Completion", requirement: "Day 38 item, retained as stated", dependency: "Applicability to be taken from the finalized scope", status: "PENDING" },
  { name: "Third-party dependencies", purpose: "Identify third-party dependencies during technical analysis.", module: "Research", requirement: "Third-party dependency analysis", dependency: "Phase 1 requirements", status: "PLANNED" },
  { name: "Instagram Ads enquiry data", purpose: "Instagram Ads enquiry count and data availability for Live Office.", module: "Live Office Screen", requirement: "Shown as a Live Office count; live fetch is under feasibility review", dependency: "API access/permissions and data source availability", status: "TECHNICAL FEASIBILITY" },
  { name: "Facebook Ads enquiry data", purpose: "Facebook Ads enquiry count and data availability for Live Office.", module: "Live Office Screen", requirement: "Shown as a Live Office count; live fetch is under feasibility review", dependency: "API access/permissions and data source availability", status: "TECHNICAL FEASIBILITY" },
  { name: "Website enquiry data", purpose: "Website enquiry count for Live Office, including whether that data is available for automated live update.", module: "Live Office Screen", requirement: "The count is part of the Live Office UI. Availability for automated live update is part of the Day 27 research.", dependency: "API access/permissions and data source availability", status: "TECHNICAL FEASIBILITY" }
];

PLAN.dependencies = [
  { name: "Complete Phase 1 requirements", type: "Business clarification", detail: "Day 1 studies the complete Phase 1 requirements.", status: "REQUIRED", sprint: "Sprint 01" },
  { name: "Student data collection requirements", type: "Business clarification", detail: "Identified with the student journey on Day 2.", status: "REQUIRED", sprint: "Sprint 01" },
  { name: "Finalized requirements for recommendation / business rules", type: "Business clarification", detail: "Recommendation/business-rule implementation is based on finalized requirements.", status: "PENDING", sprint: "Sprint 04" },
  { name: "Other finalized college information", type: "Data", detail: "College data structure includes other finalized college information. Those fields are not listed beyond this phrase.", status: "PENDING", sprint: "Sprint 05" },
  { name: "Technically uncertain requirements", type: "Technical feasibility", detail: "Day 5 identifies technically uncertain requirements. The named unconfirmed item in this plan is Live Office data fetch and automated live update.", status: "TBC", sprint: "Sprint 01, Sprint 06" },
  { name: "Third-party dependency analysis", type: "Third-party access", detail: "Third-party dependencies are analysed on Day 4.", status: "REQUIRED", sprint: "Sprint 01" },
  { name: "Data source availability", type: "API access", detail: "Required before Live Office live fetch can be confirmed.", status: "TECHNICAL FEASIBILITY", sprint: "Sprint 06" },
  { name: "API access/permissions", type: "API access", detail: "Required for fetching enquiry data from the required sources.", status: "TECHNICAL FEASIBILITY", sprint: "Sprint 06" },
  { name: "Authentication/API credentials required", type: "Credentials", detail: "Credentials required for the Live Office data-fetch research.", status: "CLIENT INPUT REQUIRED", sprint: "Sprint 06" },
  { name: "Instagram/Facebook/Website enquiry data availability", type: "Data", detail: "Availability of these enquiry sources must be confirmed.", status: "TECHNICAL FEASIBILITY", sprint: "Sprint 06" },
  { name: "Real-time vs periodic data fetching", type: "Technical feasibility", detail: "The fetch pattern is not chosen until research confirms it.", status: "TECHNICAL FEASIBILITY", sprint: "Sprint 06" },
  { name: "WebSocket / polling / webhook feasibility", type: "Technical feasibility", detail: "These options are to be researched. None is selected in this plan.", status: "TECHNICAL FEASIBILITY", sprint: "Sprint 06" },
  { name: "Known technical dependencies", type: "Technical feasibility", detail: "Recorded as part of the Day 40 QA handover.", status: "PENDING", sprint: "Sprint 08" },
  { name: "Notification/integration points where applicable", type: "Approvals", detail: "Included in final integration only where applicable. Specific channels are not defined in this plan.", status: "PENDING", sprint: "Sprint 08" },
  { name: "Testing environment preparation", type: "Environment", detail: "Prepared at development handover so the separate QA phase can start.", status: "PLANNED", sprint: "Sprint 08" }
];

PLAN.frontendScope = [
  { group: "UI/UX", items: ["Project UI foundation", "Typography", "Color system", "Buttons", "Cards", "Form components", "Input components", "Dropdowns", "Modal components", "Table components", "Common responsive components", "Final UI consistency review", "Pending UI corrections", "Missing screen completion", "Common component consistency", "Final frontend development"] },
  { group: "Pages / Screens", items: ["Homepage", "Banner slider", "Qualification selection", "Stream selection", "Course selection", "Course Explorer", "Top 10 Colleges", "College listing", "College details", "Search/filter interface", "Scholarship information section", "General counselling UI", "Step-by-step enquiry form", "Admin Dashboard UI", "College Master UI", "Course & Filter Master UI", "Live Office Screen UI", "Lead Routing UI", "Admin login", "Dashboard", "Announcement sections", "Campaign/scholarship sections", "Complete college information", "Incoming enquiry view", "Full-screen Live Office layout"] },
  { group: "Components", items: ["Reusable components", "Layout", "Header/footer", "Sidebar", "Summary cards", "Cards", "Buttons", "Modal components", "Table components", "Dropdowns", "Form components", "Input components", "Common responsive components"] },
  { group: "Forms", items: ["Step-by-step enquiry form", "Student information", "Qualification/marks", "Course interest", "Contact details", "Enquiry confirmation", "Guidance form", "Counselling enquiry", "Add college", "Edit college"] },
  { group: "Validation", items: ["Validation/error states", "Validation", "Form validation", "Success/error messages", "API error handling"] },
  { group: "Navigation", items: ["Navigation flow", "Routing", "Header/footer", "Sidebar", "Navigation"] },
  { group: "Responsive design", items: ["Responsive layouts", "Common responsive components", "Responsive framework", "Responsive corrections", "Responsive/full-screen presentation layout", "Responsive layout completion"] },
  { group: "API integration", items: ["API service structure", "Environment configuration", "Complete frontend/backend integration", "Frontend/API integration", "Final frontend/backend integration", "API error handling", "Loading states", "Empty states"] },
  { group: "State / data handling", items: ["Dynamic selection", "Requirement-based college display", "Source-wise enquiry display", "Today's enquiry count", "Website enquiry count", "Instagram Ads enquiry count", "Facebook Ads enquiry count", "Live indicator", "Lead status", "Assignment", "Routing information", "Enquiry status"] },
  { group: "User interactions", items: ["Qualification selection", "Stream selection", "Course selection", "Submission", "Counsellor action", "Action controls", "Status management", "Search", "Filters"] }
];

PLAN.backendScope = [
  { group: "Authentication", items: ["Authentication requirements", "Admin authentication", "Session/token handling", "Session/authentication handling"] },
  { group: "Authorization", items: ["Permission handling"] },
  { group: "Business logic", items: ["Business logic", "Business logic completion", "Qualification/course rules", "College matching rules", "Enquiry rules", "Lead priority", "Priority logic", "Recommendation/business-rule implementation based on finalized requirements"] },
  { group: "CRUD", items: ["College CRUD APIs", "Add college", "Edit college", "View college", "Stream management", "Course management", "Specialization", "Filter management"] },
  { group: "Data processing", items: ["Enquiry aggregation API", "Source-wise enquiry API", "Data relationships", "Database relationships", "Follow-up data handling"] },
  { group: "Validation", items: ["Validation", "College validation", "CRUD validation", "Validation completion", "Duplicate/invalid data handling", "Invalid input handling"] },
  { group: "Workflow management", items: ["Assignment logic", "College assignment", "Counsellor handling", "Complete lead workflow integration", "Admin workflow completion"] },
  { group: "Status management", items: ["Enquiry status foundation", "Status handling", "Status management", "College status API", "Status update API", "Status transition logic", "Status transitions", "Lead status update"] },
  { group: "Error handling", items: ["Error handling", "API error handling", "API response handling", "Empty data handling"] },
  { group: "Integration logic", items: ["Complete module integration", "Frontend/API integration", "Final frontend/backend integration", "Identify required Live Office APIs"] },
  { group: "Completion", items: ["Complete pending APIs", "Pending API completion", "API response optimization", "Database finalization", "Data consistency"] }
];

PLAN.notes = [
  { title: "Development and QA are separate", body: "Total development duration is 40 working days. Testing / QA is an additional 10 working days. The total project working timeline is 50 working days. QA is shown separately, beyond the 40 development days." },
  { title: "Week 8 does not include testing", body: "Week 8 contains development closure and deployment preparation only. Testing tasks are not part of Week 8. Testing is the separate 10-working-day QA phase." },
  { title: "Week 7 completes remaining backend and API work", body: "Remaining backend and API work is completed in Week 7, together with business rules, integration, edge cases, and the development-complete build." },
  { title: "One Week 6 item is TBD", body: "Within Week 6, one item only is TBD / Research Required: Live Office Data Fetch & Automated Live Update (Day 27). It is not a confirmed development commitment." },
  { title: "Live Office client statement", body: "The technical feasibility of fetching live enquiry data from the required sources and automatically updating the Live Office screen will be researched and confirmed before implementation. The final approach will depend on API availability, access permissions, third-party limitations and technical feasibility." },
  { title: "Live Office integration is conditional", body: "Day 30 includes Live Office integration where technically supported. The Week 6 deliverable is Lead Routing module + Live Office core development, with live data/auto-update subject to technical feasibility confirmation." },
  { title: "Recommendation rules follow finalized requirements", body: "Recommendation/business-rule implementation is based on finalized requirements. This plan does not add rules beyond that statement." },
  { title: "College information remains as stated", body: "The college data structure supports basic information, location, courses, fees, seats, scholarship details, and other finalized college information. Further fields are not assumed." },
  { title: "Notifications only where applicable", body: "Day 38 includes notification/integration points where applicable. Specific notification channels are not defined in this plan." },
  { title: "Database is planned, then finalized", body: "Database structure is to be finalized during technical analysis, through entity identification and table/relationship planning, with database relationships in Week 7 and database finalization in Week 8. This plan does not publish a physical table list." },
  { title: "Document control fields not supplied", body: "Version, document status, prepared for, and prepared by were not supplied. They are marked To Be Confirmed." },
  { title: "Best Academy first priority", body: "The agreed lead flow gives Best Academy first priority before counsellor contact, interest and eligibility check, college identification, college assignment, and receipt of the enquiry by the college." }
];

PLAN.handover = {
  developmentComplete: [
    "Final development build",
    "Development checklist",
    "API documentation",
    "Module completion checklist",
    "Known technical dependencies",
    "QA handover",
    "Testing environment preparation",
    "Development Complete → QA Handover Build"
  ],
  flow: ["Development Complete", "QA / Testing", "UAT", "Final Release"],
  uatNote: "Client/UAT Support + Fix Verification is QA Day 9. Final Regression + QA Sign-off is QA Day 10.",
  releaseNote: "Final release follows QA sign-off. Release activities beyond the QA sign-off are not specified in this plan."
};
