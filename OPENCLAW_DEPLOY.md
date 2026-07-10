# Deploying the Spatial Transcriptomics Pipeline in OpenClaw

This guide explains how to deploy Maiqi Zhang's spatial transcriptomics analysis pipeline inside OpenClaw for automated, ongoing analysis with new datasets.

## What This Does

OpenClaw acts as an AI agent that automatically runs the full analysis pipeline when a new dataset is dropped into the project folder. It sends an email notification when the run finishes, and can also be triggered on demand from a browser dashboard or iMessage.

The pipeline runs three stages in sequence:

1. **Ensemble Clustering** — groups cells by gene expression similarity using K-means, Hierarchical, and GMM combined (~30-60 min)
2. **Biological Annotation** — identifies cell types using 374 markers across 8 ovarian cell types (~20 min)
3. **AI Agent Discovery** — autonomously generates and tests biological hypotheses (~10-20 min)

## Prerequisites

- macOS (the auto-run watcher uses macOS launchd)
- Python 3.8+
- Node.js 22+
- An Anthropic or OpenAI API key
- A Gmail account (for email notifications)

## Installation

### 1. Clone the Repository

```bash
git clone <repo-url>
cd "Spatial Transcriptomics Analysis"
```

### 2. Install Python Dependencies

```bash
python -m venv .venv
source .venv/bin/activate
pip install numpy pandas scipy scikit-learn h5py matplotlib seaborn umap-learn openai
```

### 3. Install OpenClaw

```bash
npm install -g openclaw@latest
```

### 4. Run OpenClaw Setup

```bash
openclaw onboard --install-daemon
```

During setup:
- Select your AI provider (Anthropic recommended if you have a Claude subscription)
- Select **ClickClack** as the channel to use the browser dashboard
- Skip optional skills and search providers

### 5. Configure Environment Variables

Create a `.env` file in the project folder:

```bash
GMAIL_USER=your@gmail.com
NOTIFY_EMAIL_TO=your@gmail.com
GMAIL_APP_PASSWORD=your-app-password
PYTHONUNBUFFERED=1
```

To get a Gmail App Password: Google Account → Security → 2-Step Verification → App Passwords. Generate one and paste it above.

## Running the Pipeline

### Option 1: Automatic (Drop and Walk Away)

Drop any `.gef` file into the project folder. The pipeline starts automatically within ~6 seconds via a macOS launchd file watcher. You will receive an email when it finishes with success/failure status and timing.

The watcher is anti-loop safe — it will not re-run if the same file is dropped twice or if a run is already in progress.

### Option 2: On Demand from the Dashboard

Open the browser dashboard:

```bash
openclaw dashboard
```

Then type in the chat:

```
Run the full pipeline
```

### Option 3: On Demand via iMessage

Configure iMessage as a channel:

```bash
openclaw configure --section channels
```

Select iMessage, then text your Mac from your phone:

```
Run the full pipeline
```

## Using a New Dataset

1. Obtain a `.gef` file output from the Stereo-seq Analysis Workflow (SAW)
2. Drop it into the project folder
3. The pipeline runs automatically and outputs results to:
   - `ensemble_output/` — clustering results and plots
   - `knowledge_integration_output/` — cell type assignments
   - `autonomous_agent_output/` — AI-generated hypotheses and discoveries

No code changes are needed between datasets.

## Output Files

| Folder | Key Files |
|--------|-----------|
| `ensemble_output/` | `ensemble_results.json`, `clustering_analysis.png`, `comprehensive_report.txt` |
| `knowledge_integration_output/` | `cell_type_assignments.csv`, `marker_detection_report.txt` |
| `autonomous_agent_output/` | `autonomous_discoveries.json`, `autonomous_discovery_report.txt` |

## Sample Outputs

### Ensemble Clustering Performance
Comparison of silhouette scores, cluster counts, execution times, and improvement over individual methods. The ensemble (blue dashed line) achieves a silhouette score of 0.538 — outperforming all individual methods.

![Comprehensive Clustering Analysis](docs/images/comprehensive_clustering_analysis.png)

### Method Diversity & Quality
Shows how different the three clustering methods are from each other (left) and their quality metrics (right). Low similarity between methods (hierarchical vs k-means = 0.00) confirms the ensemble is combining genuinely diverse perspectives.

![Method Diversity and Quality](docs/images/method_diversity_quality.png)

---

### Biological Annotation: Overview
Summary dashboard showing spatial distribution of all 8 annotated cell types, confidence breakdown (High/Medium/Low/Unassigned), and marker gene detection rates. Out of 24,930 cells, 22,100 (88.6%) were successfully annotated across 8 cell types using 211 of 428 marker genes.

![Annotation Overview](docs/images/annotation_overview.png)

### Biological Annotation: Cell Type Map
Spatial scatter plot of all 24,930 cells colored by cell type across the tissue coordinate space (x: 7000–12000, y: 5000–9000). Shows the physical distribution of Granulosa Cells, Stromal Fibroblasts, Endothelial Cells, Oocytes, Theca Cells, and immune populations across the ovarian section.

![Cell Type Assignments](docs/images/cell_type_assignments.png)

### Biological Annotation: Confidence Analysis
Spatial heatmap of per-cell annotation confidence scores alongside a histogram of the score distribution. Mean confidence of 1.163 indicates reliable assignments; cells with low confidence are flagged for manual review.

![Confidence Analysis](docs/images/confidence_analysis.png)

### Biological Annotation: Anatomical Structures
Spatial plots of the 5 identified anatomical structures within the ovary: Primordial Follicles (3,816 cells), Primary Follicles (3,756), Secondary Follicles (3,756), Antral Follicles (3,583), and Corpus Luteum (4,580).

![Anatomical Structures](docs/images/anatomical_structures.png)

### Biological Annotation: Spatial Organization
Left: local cell density heatmap showing high-density tissue core regions (red) vs. sparse periphery (blue). Right: spatial centroids of each cell type, revealing how cell populations are physically partitioned across the tissue.

![Spatial Organization](docs/images/spatial_organization.png)

## Notes

- The first stage (ensemble clustering) is the most compute-intensive. Expect 30-60 minutes on a standard laptop.
- `ai_agent.py` uses an LLM for hypothesis generation. Set `OPENAI_API_KEY` in `.env` to enable this. It will fall back to rule-based hypotheses without a key.
- Keep `.env` out of version control. It is already listed in `.gitignore`.

## Based On

Maiqi Zhang, *Enhanced Autonomous Spatial Transcriptomics Analysis*, MS Thesis, San Jose State University, 2026. Advisor: Dr. William Andreopoulos.