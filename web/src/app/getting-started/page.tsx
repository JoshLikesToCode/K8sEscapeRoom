import { GettingStartedWizard } from '@/components/GettingStartedWizard'

export const metadata = {
  title: 'Getting Started | K8sEscapeRoom',
  description: 'Get started with K8sEscapeRoom in minutes. Debug Kubernetes failures and escape each room.',
}

export default function GettingStartedPage() {
  return (
    <div className="min-h-screen bg-gray-950">
      {/* Header */}
      <header className="border-b border-gray-800 bg-gray-950/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <a href="/" className="flex items-center gap-2">
            <span className="text-xl font-bold text-white">K8sEscapeRoom</span>
          </a>
          <nav className="flex items-center gap-6">
            <a href="/play" className="text-gray-400 hover:text-white transition-colors text-sm">
              Play
            </a>
            <a
              href="https://github.com/JoshLikesToCode/K8sEscapeRoom"
              target="_blank"
              rel="noopener noreferrer"
              className="text-gray-400 hover:text-white transition-colors text-sm"
            >
              GitHub
            </a>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-5xl mx-auto px-6 py-12">
        {/* Hero */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-white mb-4">
            Get Started in Minutes
          </h1>
          <p className="text-xl text-gray-400 max-w-2xl mx-auto">
            Debug Kubernetes failures. Escape each room. Learn by doing.
          </p>
        </div>

        {/* Wizard */}
        <GettingStartedWizard />

        {/* Footer */}
        <div className="mt-16 pt-8 border-t border-gray-800">
          <div className="grid md:grid-cols-2 gap-8 text-center md:text-left max-w-2xl mx-auto">
            <div>
              <h3 className="text-white font-semibold mb-2">Need Help?</h3>
              <p className="text-gray-500 text-sm">
                Run <code className="text-terminal-green">escape doctor</code> to diagnose issues
              </p>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-2">Report Issues</h3>
              <p className="text-gray-500 text-sm">
                <a
                  href="https://github.com/JoshLikesToCode/K8sEscapeRoom/issues"
                  className="text-k8s-blue hover:underline"
                >
                  Open an issue on GitHub
                </a>
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
