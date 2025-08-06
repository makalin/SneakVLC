import { useState, useRef } from 'react'
import { Upload, QrCode, Copy, Check, AlertCircle } from 'lucide-react'
import QRCode from 'qrcode.react'

const Sender: React.FC = () => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [isGenerating, setIsGenerating] = useState(false)
  const [magnetUri, setMagnetUri] = useState('')
  const [copied, setCopied] = useState(false)
  const [error, setError] = useState('')
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setSelectedFile(file)
      setError('')
      setMagnetUri('')
    }
  }

  const generateMagnetUri = async () => {
    if (!selectedFile) {
      setError('Please select a file first')
      return
    }

    setIsGenerating(true)
    setError('')

    try {
      // Generate file hash
      const arrayBuffer = await selectedFile.arrayBuffer()
      const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer)
      const hashArray = Array.from(new Uint8Array(hashBuffer))
      const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')

      // Get local IP (mock for now)
      const localIP = '192.168.1.100' // This would be determined dynamically
      const port = 12345

      const uri = `sneakvlc://${hash}?ip=${localIP}&port=${port}`
      setMagnetUri(uri)
    } catch (err) {
      setError('Failed to generate magnet URI')
      console.error(err)
    } finally {
      setIsGenerating(false)
    }
  }

  const copyToClipboard = async () => {
    if (magnetUri) {
      try {
        await navigator.clipboard.writeText(magnetUri)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
      } catch (err) {
        setError('Failed to copy to clipboard')
      }
    }
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Sender</h1>
        <p className="text-gray-600 mt-1">
          Share files using SneakVLC P2P transfer
        </p>
      </div>

      {/* File Selection */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Select File</h2>
        
        <div className="space-y-4">
          <div
            className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-sneakvlc-400 transition-colors cursor-pointer"
            onClick={() => fileInputRef.current?.click()}
          >
            <Upload className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-lg font-medium text-gray-900 mb-2">
              Choose a file to share
            </p>
            <p className="text-sm text-gray-500">
              Click to browse or drag and drop
            </p>
            <input
              ref={fileInputRef}
              type="file"
              className="hidden"
              onChange={handleFileSelect}
              accept="*/*"
            />
          </div>

          {selectedFile && (
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-900">{selectedFile.name}</p>
                  <p className="text-sm text-gray-500">
                    {formatFileSize(selectedFile.size)}
                  </p>
                </div>
                <button
                  onClick={() => setSelectedFile(null)}
                  className="text-red-600 hover:text-red-700 text-sm font-medium"
                >
                  Remove
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Generate QR Code */}
      {selectedFile && (
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Generate Transfer Code</h2>
          
          <div className="space-y-4">
            <button
              onClick={generateMagnetUri}
              disabled={isGenerating}
              className="btn-primary flex items-center justify-center space-x-2 w-full"
            >
              <QrCode className="h-5 w-5" />
              <span>{isGenerating ? 'Generating...' : 'Generate QR Code'}</span>
            </button>

            {error && (
              <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
                <AlertCircle className="h-5 w-5 text-red-500" />
                <p className="text-sm text-red-700">{error}</p>
              </div>
            )}

            {magnetUri && (
              <div className="space-y-4">
                <div className="bg-gray-50 rounded-lg p-6 text-center">
                  <QRCode
                    value={magnetUri}
                    size={200}
                    level="M"
                    includeMargin={true}
                    className="mx-auto"
                  />
                </div>

                <div className="space-y-2">
                  <label className="block text-sm font-medium text-gray-700">
                    Magnet URI
                  </label>
                  <div className="flex space-x-2">
                    <input
                      type="text"
                      value={magnetUri}
                      readOnly
                      className="input-field flex-1 font-mono text-sm"
                    />
                    <button
                      onClick={copyToClipboard}
                      className="btn-secondary flex items-center space-x-2"
                    >
                      {copied ? (
                        <Check className="h-4 w-4" />
                      ) : (
                        <Copy className="h-4 w-4" />
                      )}
                      <span>{copied ? 'Copied!' : 'Copy'}</span>
                    </button>
                  </div>
                </div>

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <h3 className="font-medium text-blue-900 mb-2">How to use:</h3>
                  <ol className="text-sm text-blue-800 space-y-1">
                    <li>1. Scan the QR code with a receiver device</li>
                    <li>2. Or copy the magnet URI and share it manually</li>
                    <li>3. The receiver will connect and start downloading</li>
                  </ol>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Instructions */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">How SneakVLC Works</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              1
            </div>
            <p>
              Your file is embedded into an H.264 video stream using VLC's x264 encoder
            </p>
          </div>
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              2
            </div>
            <p>
              A QR code containing the connection details is generated and displayed
            </p>
          </div>
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              3
            </div>
            <p>
              Receivers scan the QR code and connect to your stream to download the file
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Sender 