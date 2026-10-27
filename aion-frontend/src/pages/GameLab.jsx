import MazeGame from './MazeGame'

function GameLab({ onBack }) {
  return (
    <main className="game-lab">

      <button
        className="back-button"
        onClick={onBack}
      >
        ← Back to AION
      </button>


      <section className="game-lab-header">

        <div>
          <div className="section-eyebrow">
            AI GAME LAB
          </div>

          <h1>Maze Escape</h1>

          <p>
            Competitive AI game demonstrating search,
            heuristic evaluation, and adversarial decision making.
          </p>
        </div>

      </section>


      <MazeGame />

    </main>
  )
}

export default GameLab