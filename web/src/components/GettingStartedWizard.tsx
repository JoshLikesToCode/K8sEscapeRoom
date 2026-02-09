'use client'

import { useState } from 'react'

type OS = 'macos' | 'windows' | 'linux'
type Arch = 'arm64' | 'x64'
type ClusterType = 'kind' | 'minikube' | 'existing'

interface StepConfig {
  os: OS
  arch?: Arch
  cluster: ClusterType
}

export function GettingStartedWizard() {
  const [step, setStep] = useState(1)
  const [config, setConfig] = useState<StepConfig>({
    os: 'macos',
    cluster: 'kind',
  })

  const setOS = (os: OS) => {
    setConfig((prev) => ({
      ...prev,
      os,
      arch: os === 'macos' ? 'arm64' : 'x64',
    }))
    setStep(2)
  }

  const setArch = (arch: Arch) => {
    setConfig((prev) => ({ ...prev, arch }))
    setStep(3)
  }

  const setCluster = (cluster: ClusterType) => {
    setConfig((prev) => ({ ...prev, cluster }))
    setStep(4)
  }

  return (
    <div className="space-y-8">
      {/* Progress */}
      <div className="flex items-center justify-center gap-2">
        {[1, 2, 3, 4].map((s) => (
          <div
            key={s}
            className={`h-2 w-16 rounded-full transition-colors ${
              s <= step ? 'bg-k8s-blue' : 'bg-gray-800'
            }`}
          />
        ))}
      </div>

      {/* Step 1: OS Selection */}
      <StepSection
        stepNumber={1}
        title="Choose your operating system"
        active={step >= 1}
        completed={step > 1}
      >
        <div className="grid grid-cols-3 gap-4">
          <OSButton
            os="macos"
            label="macOS"
            icon={<AppleIcon />}
            selected={config.os === 'macos'}
            onClick={() => setOS('macos')}
          />
          <OSButton
            os="linux"
            label="Linux"
            icon={<LinuxIcon />}
            selected={config.os === 'linux'}
            onClick={() => setOS('linux')}
          />
          <OSButton
            os="windows"
            label="Windows"
            icon={<WindowsIcon />}
            selected={config.os === 'windows'}
            onClick={() => setOS('windows')}
          />
        </div>
      </StepSection>

      {/* Step 2: Architecture (macOS only) */}
      {config.os === 'macos' && (
        <StepSection
          stepNumber={2}
          title="Select your Mac type"
          active={step >= 2}
          completed={step > 2}
        >
          <div className="grid grid-cols-2 gap-4 max-w-md mx-auto">
            <button
              onClick={() => setArch('arm64')}
              className={`p-4 rounded-xl border-2 transition-all ${
                config.arch === 'arm64'
                  ? 'border-k8s-blue bg-k8s-blue/10'
                  : 'border-gray-800 hover:border-gray-700'
              }`}
            >
              <div className="text-white font-semibold">Apple Silicon</div>
              <div className="text-gray-500 text-sm">M1, M2, M3 chips</div>
            </button>
            <button
              onClick={() => setArch('x64')}
              className={`p-4 rounded-xl border-2 transition-all ${
                config.arch === 'x64'
                  ? 'border-k8s-blue bg-k8s-blue/10'
                  : 'border-gray-800 hover:border-gray-700'
              }`}
            >
              <div className="text-white font-semibold">Intel</div>
              <div className="text-gray-500 text-sm">Older Macs</div>
            </button>
          </div>
        </StepSection>
      )}

      {/* Step 2/3: Cluster Selection */}
      <StepSection
        stepNumber={config.os === 'macos' ? 3 : 2}
        title="Choose your Kubernetes cluster"
        active={step >= (config.os === 'macos' ? 3 : 2)}
        completed={step > (config.os === 'macos' ? 3 : 2)}
      >
        <div className="grid grid-cols-3 gap-4">
          <ClusterButton
            type="kind"
            label="kind"
            description="Recommended for beginners"
            recommended
            selected={config.cluster === 'kind'}
            onClick={() => setCluster('kind')}
          />
          <ClusterButton
            type="minikube"
            label="minikube"
            description="Alternative option"
            selected={config.cluster === 'minikube'}
            onClick={() => setCluster('minikube')}
          />
          <ClusterButton
            type="existing"
            label="Existing Cluster"
            description="Use your own cluster"
            selected={config.cluster === 'existing'}
            onClick={() => setCluster('existing')}
          />
        </div>
      </StepSection>

      {/* Step 3/4: Installation Instructions */}
      <StepSection
        stepNumber={config.os === 'macos' ? 4 : 3}
        title="Follow these steps"
        active={step >= 4}
        completed={false}
      >
        <InstallationSteps config={config} />
      </StepSection>
    </div>
  )
}

function StepSection({
  stepNumber,
  title,
  active,
  completed,
  children,
}: {
  stepNumber: number
  title: string
  active: boolean
  completed: boolean
  children: React.ReactNode
}) {
  return (
    <div
      className={`transition-opacity ${
        active ? 'opacity-100' : 'opacity-40 pointer-events-none'
      }`}
    >
      <div className="flex items-center gap-3 mb-4">
        <div
          className={`h-8 w-8 rounded-full flex items-center justify-center text-sm font-bold ${
            completed
              ? 'bg-terminal-green text-black'
              : active
              ? 'bg-k8s-blue text-white'
              : 'bg-gray-800 text-gray-500'
          }`}
        >
          {completed ? '✓' : stepNumber}
        </div>
        <h2 className="text-lg font-semibold text-white">{title}</h2>
      </div>
      <div className="ml-11">{children}</div>
    </div>
  )
}

function OSButton({
  os,
  label,
  icon,
  selected,
  onClick,
}: {
  os: OS
  label: string
  icon: React.ReactNode
  selected: boolean
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className={`p-6 rounded-xl border-2 transition-all flex flex-col items-center gap-3 ${
        selected
          ? 'border-k8s-blue bg-k8s-blue/10'
          : 'border-gray-800 hover:border-gray-700'
      }`}
    >
      <div className="h-12 w-12 text-gray-400">{icon}</div>
      <div className="text-white font-semibold">{label}</div>
    </button>
  )
}

function ClusterButton({
  type,
  label,
  description,
  recommended,
  selected,
  onClick,
}: {
  type: ClusterType
  label: string
  description: string
  recommended?: boolean
  selected: boolean
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className={`p-4 rounded-xl border-2 transition-all text-left relative ${
        selected
          ? 'border-k8s-blue bg-k8s-blue/10'
          : 'border-gray-800 hover:border-gray-700'
      }`}
    >
      {recommended && (
        <span className="absolute -top-2 -right-2 px-2 py-0.5 bg-terminal-green text-black text-xs font-bold rounded-full">
          Recommended
        </span>
      )}
      <div className="text-white font-semibold">{label}</div>
      <div className="text-gray-500 text-sm">{description}</div>
    </button>
  )
}

function InstallationSteps({ config }: { config: StepConfig }) {
  const { os, arch, cluster } = config

  // Determine platform string for downloads
  const platform =
    os === 'macos'
      ? arch === 'arm64'
        ? 'osx-arm64'
        : 'osx-x64'
      : os === 'linux'
      ? 'linux-x64'
      : 'win-x64'

  const isWindows = os === 'windows'

  return (
    <div className="space-y-6">
      {/* Prerequisites */}
      <div className="bg-gray-900 rounded-xl p-6 border border-gray-800">
        <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
          <span className="text-terminal-green">1.</span> Install Prerequisites
        </h3>

        <div className="space-y-4">
          {/* Docker */}
          <div>
            <div className="text-gray-400 text-sm mb-2">Docker Desktop</div>
            <a
              href={
                os === 'macos'
                  ? 'https://docs.docker.com/desktop/install/mac-install/'
                  : os === 'windows'
                  ? 'https://docs.docker.com/desktop/install/windows-install/'
                  : 'https://docs.docker.com/engine/install/'
              }
              target="_blank"
              rel="noopener noreferrer"
              className="text-k8s-blue hover:underline text-sm"
            >
              Download Docker Desktop →
            </a>
          </div>

          {/* kubectl */}
          <div>
            <div className="text-gray-400 text-sm mb-2">kubectl</div>
            <CodeBlock>
              {os === 'macos'
                ? 'brew install kubectl'
                : os === 'windows'
                ? 'winget install Kubernetes.kubectl'
                : 'sudo apt-get update && sudo apt-get install -y kubectl'}
            </CodeBlock>
          </div>

          {/* kind/minikube */}
          {cluster !== 'existing' && (
            <div>
              <div className="text-gray-400 text-sm mb-2">{cluster}</div>
              <CodeBlock>
                {cluster === 'kind'
                  ? os === 'macos'
                    ? 'brew install kind'
                    : os === 'windows'
                    ? 'winget install Kubernetes.kind'
                    : 'go install sigs.k8s.io/kind@latest'
                  : os === 'macos'
                  ? 'brew install minikube'
                  : os === 'windows'
                  ? 'winget install Kubernetes.minikube'
                  : 'curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube'}
              </CodeBlock>
            </div>
          )}
        </div>
      </div>

      {/* Install CLI */}
      <div className="bg-gray-900 rounded-xl p-6 border border-gray-800">
        <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
          <span className="text-terminal-green">2.</span> Install the CLI
        </h3>

        {isWindows ? (
          <div className="space-y-3">
            <p className="text-gray-400 text-sm">
              Download the latest release and extract to a folder in your PATH:
            </p>
            <a
              href="https://github.com/jsburckhardt/K8sEscapeRoom/releases/latest"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-4 py-2 bg-k8s-blue text-white rounded-lg hover:bg-k8s-blue/80 transition-colors"
            >
              Download escape-win-x64.zip
            </a>
          </div>
        ) : (
          <div className="space-y-3">
            <p className="text-gray-400 text-sm">Quick install:</p>
            <CodeBlock>
              {`curl -fsSL https://raw.githubusercontent.com/jsburckhardt/K8sEscapeRoom/main/scripts/install.sh | bash`}
            </CodeBlock>
            <p className="text-gray-500 text-xs">
              Or download manually from{' '}
              <a
                href="https://github.com/jsburckhardt/K8sEscapeRoom/releases/latest"
                className="text-k8s-blue hover:underline"
              >
                GitHub Releases
              </a>
            </p>
          </div>
        )}
      </div>

      {/* Clone Repo */}
      <div className="bg-gray-900 rounded-xl p-6 border border-gray-800">
        <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
          <span className="text-terminal-green">3.</span> Clone the Repository
        </h3>
        <CodeBlock>
          git clone https://github.com/jsburckhardt/K8sEscapeRoom.git{'\n'}
          cd K8sEscapeRoom
        </CodeBlock>
      </div>

      {/* Start */}
      <div className="bg-gray-900 rounded-xl p-6 border border-gray-800">
        <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
          <span className="text-terminal-green">4.</span> Start Escaping!
        </h3>

        <div className="space-y-4">
          <div>
            <div className="text-gray-400 text-sm mb-2">Check your setup:</div>
            <CodeBlock>escape doctor</CodeBlock>
          </div>

          <div>
            <div className="text-gray-400 text-sm mb-2">Start the tutorial:</div>
            <CodeBlock>escape quickstart</CodeBlock>
          </div>
        </div>
      </div>

      {/* Success Message */}
      <div className="bg-terminal-green/10 border border-terminal-green/30 rounded-xl p-6 text-center">
        <div className="text-terminal-green text-2xl mb-2">🎮</div>
        <div className="text-white font-semibold mb-2">Ready to escape?</div>
        <p className="text-gray-400 text-sm">
          Follow the steps above, then run <code className="text-terminal-green">escape quickstart</code> to begin!
        </p>
      </div>
    </div>
  )
}

function CodeBlock({ children }: { children: React.ReactNode }) {
  const [copied, setCopied] = useState(false)
  const code = typeof children === 'string' ? children : ''

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="relative group">
      <pre className="bg-gray-800 rounded-lg p-4 font-mono text-sm text-terminal-green overflow-x-auto">
        {children}
      </pre>
      <button
        onClick={handleCopy}
        className="absolute top-2 right-2 px-2 py-1 bg-gray-700 hover:bg-gray-600 rounded text-xs text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        {copied ? 'Copied!' : 'Copy'}
      </button>
    </div>
  )
}

// Icons
function AppleIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    </svg>
  )
}

function LinuxIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M12.504 0c-.155 0-.315.008-.48.021-4.226.333-3.105 4.807-3.17 6.298-.076 1.092-.3 1.953-1.05 3.02-.885 1.051-2.127 2.75-2.716 4.521-.278.832-.41 1.684-.287 2.489a.424.424 0 00-.11.135c-.26.268-.45.6-.663.839-.199.199-.485.267-.797.4-.313.136-.658.269-.864.68-.09.189-.136.394-.132.602 0 .199.027.4.055.536.058.399.116.728.04.97-.249.68-.28 1.145-.106 1.484.174.334.535.47.94.601.81.2 1.91.135 2.774.6.926.466 1.866.67 2.616.47.526-.116.97-.464 1.208-.946.587-.003 1.23-.269 2.26-.334.699-.058 1.574.267 2.577.2.025.134.063.198.114.333l.003.003c.391.778 1.113 1.132 1.884 1.071.771-.06 1.592-.536 2.257-1.306.631-.765 1.683-1.084 2.378-1.503.348-.199.629-.469.649-.853.023-.4-.2-.811-.714-1.376v-.097l-.003-.003c-.17-.2-.25-.535-.338-.926-.085-.401-.182-.786-.492-1.046h-.003c-.059-.054-.123-.067-.188-.135a.357.357 0 00-.19-.064c.431-1.278.264-2.55-.173-3.694-.533-1.41-1.465-2.638-2.175-3.483-.796-1.005-1.576-1.957-1.56-3.368.026-2.152.236-6.133-3.544-6.139zm.529 3.405h.013c.213 0 .396.062.584.198.19.135.33.332.438.533.105.259.158.459.166.724 0-.02.006-.04.006-.06v.105a.086.086 0 01-.004-.021l-.004-.024a1.807 1.807 0 01-.15.706.953.953 0 01-.213.335.71.71 0 00-.088-.042c-.104-.045-.198-.064-.284-.133a1.312 1.312 0 00-.22-.066c.05-.06.146-.133.183-.198.053-.128.082-.264.088-.402v-.02a1.21 1.21 0 00-.061-.4c-.045-.134-.101-.2-.183-.333-.084-.066-.167-.132-.267-.132h-.016c-.093 0-.176.03-.262.132a.8.8 0 00-.205.334 1.18 1.18 0 00-.09.4v.019c.002.089.008.179.02.267-.193-.067-.438-.135-.607-.202a1.635 1.635 0 01-.018-.2v-.02a1.772 1.772 0 01.15-.768c.082-.22.232-.406.43-.533a.985.985 0 01.594-.2zm-2.962.059h.036c.142 0 .27.048.399.135.146.129.264.288.344.465.09.199.14.4.153.667v.004c.007.134.006.2-.002.266v.08c-.03.007-.056.018-.083.024-.152.055-.274.135-.393.2.012-.09.013-.18.003-.267v-.015c-.012-.133-.04-.2-.082-.333a.613.613 0 00-.166-.267.248.248 0 00-.183-.064h-.021c-.071.006-.13.04-.186.132a.552.552 0 00-.12.27.944.944 0 00-.023.33v.015c.012.135.037.2.08.334.046.134.098.2.166.268.01.009.02.018.034.024-.07.057-.117.07-.176.136a.304.304 0 01-.131.068 2.62 2.62 0 01-.275-.402 1.772 1.772 0 01-.155-.667 1.759 1.759 0 01.08-.668 1.43 1.43 0 01.283-.535c.128-.133.26-.2.418-.2zm1.37 1.706c.332 0 .733.065 1.216.399.293.2.523.269 1.052.468h.003c.255.136.405.266.478.399v-.131a.571.571 0 01.016.47c-.123.31-.516.643-1.063.842v.002c-.268.135-.501.333-.775.465-.276.135-.588.292-1.012.267a1.139 1.139 0 01-.448-.067 3.566 3.566 0 01-.322-.198c-.195-.135-.363-.332-.612-.465v-.005h-.005c-.4-.246-.616-.512-.686-.71-.07-.268-.005-.47.193-.6.224-.135.38-.271.483-.336.104-.074.143-.102.176-.131h.002v-.003c.169-.202.436-.47.839-.601.139-.036.294-.065.466-.065zm2.8 2.142c.358 1.417 1.196 3.475 1.735 4.473.286.534.855 1.659 1.102 3.024.156-.005.33.018.513.064.646-1.671-.546-3.467-1.089-3.966-.22-.2-.232-.335-.123-.335.59.534 1.365 1.572 1.646 2.757.13.535.16 1.104.021 1.67.067.028.135.06.205.067 1.032.534 1.413.938 1.23 1.537v-.043c-.06-.003-.12 0-.18 0h-.016c.151-.467-.182-.825-1.065-1.224-.915-.4-1.646-.336-1.77.465-.008.043-.013.066-.018.135-.068.023-.139.053-.209.064-.43.268-.662.669-.793 1.187-.13.533-.17 1.156-.205 1.869v.003c-.02.334-.17.838-.319 1.35-1.5 1.072-3.58 1.538-5.348.334a2.645 2.645 0 00-.402-.533 1.45 1.45 0 00-.275-.333c.182 0 .338-.03.465-.067a.615.615 0 00.314-.334c.108-.267 0-.697-.345-1.163-.345-.467-.931-.995-1.788-1.521-.63-.4-.986-.87-1.15-1.396-.165-.534-.143-1.085-.015-1.645.245-1.07.873-2.11 1.274-2.763.107-.065.037.135-.408.974-.396.751-1.14 2.497-.122 3.854a8.123 8.123 0 01.647-2.876c.564-1.278 1.743-3.504 1.836-5.268.048.036.217.135.289.202.218.133.38.333.59.465.21.201.477.335.876.335.039.003.075.006.11.006.412 0 .73-.134.997-.268.29-.134.52-.334.74-.4h.005c.467-.135.835-.402 1.044-.7zm2.185 8.958c.037.6.343 1.245.882 1.377.588.134 1.434-.333 1.791-.765l.211-.01c.315-.007.577.01.847.268l.003.003c.208.199.305.53.391.876.085.4.154.78.409 1.066.486.527.645.906.636 1.14l.003-.007v.018l-.003-.012c-.015.262-.185.396-.498.595-.63.401-1.746.712-2.457 1.57-.618.737-1.37 1.14-2.036 1.191-.664.053-1.237-.2-1.574-.898l-.005-.003c-.21-.4-.12-1.025.056-1.69.176-.668.428-1.344.463-1.897.037-.714.076-1.335.195-1.814.117-.468.32-.753.654-.939z" />
    </svg>
  )
}

function WindowsIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801" />
    </svg>
  )
}
