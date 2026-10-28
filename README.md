# Small-Shell
**Small-Shell** is an open-source Web application generator that creates lightweight Web apps, data stores, and automated jobs instantly using only shell scripts (`bash`). 

It is designed for engineers who want to build internal web tools, form gateways, or data exchange hubs without setting up heavy web frameworks or complex databases. Since the core application logic is written 100% in Bash, it features almost zero external dependencies, immediate execution feedback, and a super-lightweight footprint.

---

### Generate App
You can generate your app and its functions instantly using the interactive `gen` command. Please review the Quick Start guide for your environment.

```
                                    |  <->  Batch CLI  {e-cron} 
 gen command  ->>>   Shell App      |  <->  Web UI/API {App shell} 
 {CLI dialog}     {Data/Job store}  |  <->  NoSQL CLI  {Data shell}
                                    |  <->  Analytics  {Pyshell}
```

* [Quick Start for Linux](https://small-shell.org/quick_start_linux/)
* [Quick Start for Mac](https://small-shell.org/quick_start_Mac/)
* [Quick Start for Container / Docker](https://small-shell.org/quick_start_container/)

### Why Use the Shell?
Shell development is intuitive, lightweight, and requires minimal setup. It allows you to run processes instantly by combining everyday terminal commands without complex programming logic. Operating directly within the file system, it provides immediate execution feedback and serves as the fastest, most native tool for OS coordination.

---

## Features
Every component is designed to be highly simple, lightweight, and pure.

### 🌐 Common Architecture
* **Destructured Programming:** Minimized code footprint with full openness and flexibility.
* **Zero Lock-in:** Integrates easily with any tool, featuring almost no external dependencies.
* **Low Learning Curve:** Easy to learn for anyone familiar with basic UNIX terminal commands.

### ⚡ App Shell (Web Application Framework)
* **Dialog-Driven Generation:** Build web applications entirely through CLI dialogs.
* **Token-Based Security:** Cookie-less architecture utilizing secure hash tokens.
* **Vanilla Frontend:** Built using pure HTML with Flexbox layout and pure JavaScript.
* **Passwordless Auth:** Base64-encrypted KEY authentication replaces traditional passwords.
* **Hybrid Gateway:** Includes a lightweight Node.js HTTP gateway while keeping core logic 100% Bash.
* **Content Flexibility:** Supports Markdown-driven rendering for custom application pages.

### 🗄️ Data Shell (NoSQL Data Store)
* **Command-Line Interface:** NoSQL data store with a UNIX-command-based interface.
* **Destructured Databox:** Simple file-system-based flat data storage.
* **Data Integrity:** Utilizes hash chains to ensure data modification traceability.

### ⏰ e-cron (Extended Job Automation)
* **Enhanced Scheduling:** Extends standard cron with simple job registration and robust logging.
* **Distributed Automation:** Define and orchestrate job dependencies across external hosts.
* **Data Hub:** Functions as a built-in Data Exchange Hub via a unified API.

---

## Best Practices
### 👥 Data Management for Teams
* Generate NoSQL & Flat Databoxes in just a few steps.
* Input and fetch records via the user-friendly [Base Web App](https://small-shell.org/app_shell_tour/) interface.
* Analyze stored data directly using UNIX commands (`grep`, `awk`, `sed`) or Python libraries.
* Create public-facing Web Forms for external users effortlessly.

### 🛠️ Application Management for Teams
* Create highly customizable [Custom Apps](https://small-shell.org/app_shell_custom/) and append features smoothly.
* Modify application behaviors using a lightweight, transparent MVC-like file structure.
* Deploy and manage lightweight static sites with ease.

### 🔄 Automation & Data Exchange via [e-cron](https://small-shell.org/automation_tour/)
* Add background tasks to cron via the intuitive `e-cron` CLI dialog.
* Manage, monitor, and audit automated job results comprehensively.
* Sync and control job workflows seamlessly across multiple edge nodes and servers.
* Construct an enterprise data exchange pipeline within minutes.
