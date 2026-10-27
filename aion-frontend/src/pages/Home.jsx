function Home({ onOpenEmergency, onOpenGameLab }) {
    return (
      <main className="home-page">
  
        <section className="home-hero">
          <div className="section-eyebrow">
            AI DECISION & STRATEGY
          </div>
  
          <h1>
            Intelligent Decision Making
          </h1>
  
          <p>
            AION brings together AI-powered decision support,
            search, pathfinding, and strategic game intelligence
            in one platform.
          </p>
        </section>
  
  
        <section className="module-grid">
  
          <div className="module-card">
  
            <div className="module-card-content">
              <div className="module-eyebrow">
                MODULE 01
              </div>
  
              <h2>
                Emergency Response
              </h2>
  
              <p>
                AI-powered disaster response and coordination
                using knowledge-based reasoning, risk assessment,
                resource allocation, and route planning.
              </p>
  
              <div className="module-features">
                <span>Risk Analysis</span>
                <span>Medical Priority</span>
                <span>Resource Allocation</span>
                <span>Route Planning</span>
              </div>
            </div>
  
            <button
              className="module-button"
              onClick={onOpenEmergency}
            >
              Open Dashboard
            </button>
  
          </div>
  
  
          <div className="module-card">
  
            <div className="module-card-content">
              <div className="module-eyebrow">
                MODULE 02
              </div>
  
              <h2>
                AI Game Lab
              </h2>
  
              <p>
                Competitive AI environment demonstrating
                heuristic search, pathfinding, Minimax,
                and Alpha-Beta pruning.
              </p>
  
              <div className="module-features">
                <span>A* Search</span>
                <span>Manhattan Heuristic</span>
                <span>Minimax</span>
                <span>Alpha-Beta Pruning</span>
              </div>
            </div>
  
            <button
              className="module-button"
              onClick={onOpenGameLab}
            >
              Open Game Lab
            </button>
  
          </div>
  
        </section>
  
  
        <section className="capabilities-section">
  
          <div className="section-eyebrow">
            AI CAPABILITIES
          </div>
  
          <div className="capabilities-list">
            <span>Knowledge Reasoning</span>
            <span>Search</span>
            <span>Decision Making</span>
            <span>Explainability</span>
            <span>Pathfinding</span>
            <span>Game AI</span>
          </div>
  
        </section>
  
      </main>
    )
  }
  
export default Home  