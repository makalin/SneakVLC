import { useState, useRef } from 'react'
import { Download, Camera, Link, AlertCircle, CheckCircle, Clock } from 'lucide-react'

const Receiver: React.FC = () => {
  const [magnetUri, setMagnetUri] = useState('')
  const [isConnecting, setIsConnecting] = useState(false)
  const [isConnected, setIsConnected] = useState(false)
  const [error, setError] = useState('')
  const [transferProgress, setTransferProgress] = useState(0)
  const [fileName, setFileName] = useState('')
  const [fileSize, setFileSize] = useState(0)
  const videoRef = useRef<HTMLVideoElement>(null)

  const handleMagnetUriChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setMagnetUri(event.target.value)
    setError('')
  }

  const parseMagnetUri = (uri: string) => {
    try {
      // Parse sneakvlc://<hash>?ip=<ip>&port=<port>
      const match = uri.match(/sneakvlc:\/\/([^?]+)\?ip=([^&]+)&port=(\d+)/)
      if (!match) {
        throw new Error('Invalid magnet URI format')
      }
      
      return {
        hash: match[1],
        ip: match[2],
        port: parseInt(match[3])
      }
    } catch (err) {
      throw new Error('Failed to parse magnet URI')
    }
  }

  const connectToTransfer = async () => {
    if (!magnetUri.trim()) {
      setError('Please enter a magnet URI')
      return
    }

    setIsConnecting(true)
    setError('')

    try {
      const { hash, ip, port } = parseMagnetUri(magnetUri)
      
      // Simulate connection process
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      // Mock file info
      setFileName(`received-file-${hash.slice(0, 8)}`)
      setFileSize(Math.floor(Math.random() * 10000000) + 1000000) // 1-10MB
      
      setIsConnected(true)
      setIsConnecting(false)
      
      // Simulate transfer progress
      simulateTransfer()
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connection failed')
      setIsConnecting(false)
    }
  }

  const simulateTransfer = () => {
    let progress = 0
    const interval = setInterval(() => {
      progress += Math.random() * 10
      if (progress >= 100) {
        progress = 100
        clearInterval(interval)
      }
      setTransferProgress(progress)
    }, 500)
  }

  const startCamera = () => {
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      navigator.mediaDevices.getUserMedia({ video: true })
        .then(stream => {
          if (videoRef.current) {
            videoRef.current.srcObject = stream
          }
        })
        .catch(err => {
          setError('Failed to access camera')
          console.error(err)
        })
    } else {
      setError('Camera not supported')
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
        <h1 className="text-2xl font-bold text-gray-900">Receiver</h1>
        <p className="text-gray-600 mt-1">
          Connect to file transfers using QR codes or magnet URIs
        </p>
      </div>

      {/* Connection Methods */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* QR Code Scanner */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Scan QR Code</h2>
          
          <div className="space-y-4">
            <div className="bg-gray-50 rounded-lg p-4 text-center">
              <Camera className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className="text-sm text-gray-600 mb-4">
                Point your camera at a SneakVLC QR code
              </p>
              <button
                onClick={startCamera}
                className="btn-primary flex items-center justify-center space-x-2 w-full"
              >
                <Camera className="h-5 w-5" />
                <span>Start Camera</span>
              </button>
            </div>

            <video
              ref={videoRef}
              autoPlay
              playsInline
              className="w-full h-48 bg-black rounded-lg object-cover"
            />
          </div>
        </div>

        {/* Manual Input */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Manual Input</h2>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Magnet URI
              </label>
              <input
                type="text"
                value={magnetUri}
                onChange={handleMagnetUriChange}
                placeholder="sneakvlc://hash?ip=192.168.1.100&port=12345"
                className="input-field font-mono text-sm"
              />
            </div>

            <button
              onClick={connectToTransfer}
              disabled={isConnecting || !magnetUri.trim()}
              className="btn-primary flex items-center justify-center space-x-2 w-full"
            >
              {isConnecting ? (
                <Clock className="h-5 w-5 animate-spin" />
              ) : (
                <Link className="h-5 w-5" />
              )}
              <span>{isConnecting ? 'Connecting...' : 'Connect'}</span>
            </button>

            {error && (
              <div className="flex items-center space-x-2 p-3 bg-red-50 border border-red-200 rounded-lg">
                <AlertCircle className="h-5 w-5 text-red-500" />
                <p className="text-sm text-red-700">{error}</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Transfer Status */}
      {isConnected && (
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Transfer Status</h2>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900">{fileName}</p>
                <p className="text-sm text-gray-500">{formatFileSize(fileSize)}</p>
              </div>
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5 text-green-500" />
                <span className="text-sm font-medium text-green-600">Connected</span>
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Progress</span>
                <span className="font-medium">{Math.round(transferProgress)}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-sneakvlc-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${transferProgress}%` }}
                />
              </div>
            </div>

            {transferProgress === 100 && (
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <div className="flex items-center space-x-2">
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <p className="text-sm font-medium text-green-700">
                    Transfer completed successfully!
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Instructions */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">How to Receive Files</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              1
            </div>
            <p>
              Scan the QR code displayed on the sender's device using your camera
            </p>
          </div>
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              2
            </div>
            <p>
              Or manually enter the magnet URI if you received it via text or email
            </p>
          </div>
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              3
            </div>
            <p>
              The system will connect to the sender's VLC stream and start downloading
            </p>
          </div>
          <div className="flex items-start space-x-3">
            <div className="w-6 h-6 bg-sneakvlc-100 text-sneakvlc-600 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
              4
            </div>
            <p>
              Once complete, the file will be saved to your downloads folder
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Receiver 