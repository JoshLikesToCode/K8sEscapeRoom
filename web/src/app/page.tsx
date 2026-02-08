import Link from 'next/link'

export default function Home() {
  return (
    <main className="min-h-screen bg-gray-950 flex flex-col">
      {/* Hero Section */}
      <div className="flex-1 flex flex-col items-center justify-center p-8">
        <div className="text-center space-y-6 max-w-3xl">
          {/* Logo */}
          <div className="flex justify-center mb-8">
            <div className="flex items-center gap-4">
              <div className="h-16 w-16 rounded-2xl bg-k8s-blue flex items-center justify-center text-white font-bold text-2xl shadow-lg shadow-k8s-blue/25">
                K8s
              </div>
            </div>
          </div>

          {/* Title */}
          <h1 className="text-5xl md:text-6xl font-bold">
            <span className="text-white">Escape</span>
            <span className="text-k8s-blue">Room</span>
          </h1>

          {/* Subtitle */}
          <p className="text-xl text-gray-400 max-w-2xl mx-auto">
            Debug Kubernetes failures to escape each room.
            <br />
            Learn by breaking things (safely).
          </p>

          {/* Terminal Preview */}
          <div className="mt-8 p-6 bg-gray-900 rounded-xl border border-gray-800 text-left max-w-xl mx-auto">
            <div className="flex items-center gap-2 mb-4">
              <div className="h-3 w-3 rounded-full bg-red-500" />
              <div className="h-3 w-3 rounded-full bg-yellow-500" />
              <div className="h-3 w-3 rounded-full bg-green-500" />
              <span className="ml-2 text-xs text-gray-500">terminal</span>
            </div>
            <pre className="font-mono text-sm">
              <code className="text-terminal-green">$ kubectl get pods</code>
              {'\n\n'}
              <code className="text-gray-400">NAME          READY   STATUS             RESTARTS</code>
              {'\n'}
              <code className="text-terminal-amber">escape-app    0/1     CrashLoopBackOff   5</code>
              {'\n\n'}
              <code className="text-gray-500"># What&apos;s causing the crash? 🔍</code>
            </pre>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-8">
            <Link
              href="/play"
              className="px-8 py-3 bg-k8s-blue text-white font-semibold rounded-lg hover:bg-k8s-blue/80 transition-colors shadow-lg shadow-k8s-blue/25"
            >
              Play Now
            </Link>
            <a
              href="https://github.com/JoshLikesToCode/K8sEscapeRoom"
              target="_blank"
              rel="noopener noreferrer"
              className="px-8 py-3 bg-gray-800 text-gray-300 font-semibold rounded-lg hover:bg-gray-700 transition-colors border border-gray-700"
            >
              View on GitHub
            </a>
          </div>

          {/* Features */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-16">
            <Feature
              icon="🔧"
              title="Real Kubernetes"
              description="No simulations. Debug actual pods, services, and deployments."
            />
            <Feature
              icon="🎯"
              title="Progressive Hints"
              description="Get help when stuck without spoiling the entire solution."
            />
            <Feature
              icon="🏆"
              title="Track Progress"
              description="Complete rooms, earn achievements, climb the leaderboard."
            />
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t border-gray-800 py-6">
        <div className="text-center text-sm text-gray-500">
          <p>Built for engineers who want to master Kubernetes troubleshooting.</p>
          <p className="mt-2">
            <Link href="/play" className="text-k8s-blue hover:underline">
              Start Playing
            </Link>
            {' · '}
            <a href="#" className="text-gray-400 hover:text-white">
              Documentation
            </a>
            {' · '}
            <a
              href="https://github.com/JoshLikesToCode/K8sEscapeRoom"
              className="text-gray-400 hover:text-white"
            >
              GitHub
            </a>
          </p>
        </div>
      </footer>
    </main>
  )
}

function Feature({
  icon,
  title,
  description,
}: {
  icon: string
  title: string
  description: string
}) {
  return (
    <div className="p-6 bg-gray-900/50 rounded-xl border border-gray-800">
      <div className="text-3xl mb-3">{icon}</div>
      <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
      <p className="text-sm text-gray-400">{description}</p>
    </div>
  )
}
