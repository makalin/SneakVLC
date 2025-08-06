import { useState } from 'react'
import { Settings as SettingsIcon, Save, RefreshCw, Server, Monitor, Wifi } from 'lucide-react'

const Settings: React.FC = () => {
  const [settings, setSettings] = useState({
    serverPort: 8080,
    vlcPort: 12345,
    networkCaching: 0,
    x264Preset: 'ultrafast',
    x264Tune: 'zerolatency',
    qrDuration: 2,
    maxTableSize: 10,
    cleanupInterval: 30,
  })

  const [isSaving, setIsSaving] = useState(false)
  const [saveStatus, setSaveStatus] = useState('')

  const handleSettingChange = (key: string, value: string | number) => {
    setSettings(prev => ({
      ...prev,
      [key]: value
    }))
  }

  const saveSettings = async () => {
    setIsSaving(true)
    setSaveStatus('')

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      setSaveStatus('Settings saved successfully!')
    } catch (error) {
      setSaveStatus('Failed to save settings')
    } finally {
      setIsSaving(false)
    }
  }

  const resetSettings = () => {
    setSettings({
      serverPort: 8080,
      vlcPort: 12345,
      networkCaching: 0,
      x264Preset: 'ultrafast',
      x264Tune: 'zerolatency',
      qrDuration: 2,
      maxTableSize: 10,
      cleanupInterval: 30,
    })
    setSaveStatus('Settings reset to defaults')
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
        <p className="text-gray-600 mt-1">
          Configure your SneakVLC system preferences
        </p>
      </div>

      {/* Server Settings */}
      <div className="card">
        <div className="flex items-center space-x-2 mb-4">
          <Server className="h-5 w-5 text-sneakvlc-600" />
          <h2 className="text-lg font-semibold text-gray-900">Server Configuration</h2>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Server Port
            </label>
            <input
              type="number"
              value={settings.serverPort}
              onChange={(e) => handleSettingChange('serverPort', parseInt(e.target.value))}
              className="input-field"
              min="1024"
              max="65535"
            />
            <p className="text-xs text-gray-500 mt-1">HTTP server port (default: 8080)</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              VLC Port
            </label>
            <input
              type="number"
              value={settings.vlcPort}
              onChange={(e) => handleSettingChange('vlcPort', parseInt(e.target.value))}
              className="input-field"
              min="1024"
              max="65535"
            />
            <p className="text-xs text-gray-500 mt-1">VLC streaming port (default: 12345)</p>
          </div>
        </div>
      </div>

      {/* VLC Settings */}
      <div className="card">
        <div className="flex items-center space-x-2 mb-4">
          <Monitor className="h-5 w-5 text-sneakvlc-600" />
          <h2 className="text-lg font-semibold text-gray-900">VLC Configuration</h2>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Network Caching (ms)
            </label>
            <input
              type="number"
              value={settings.networkCaching}
              onChange={(e) => handleSettingChange('networkCaching', parseInt(e.target.value))}
              className="input-field"
              min="0"
              max="10000"
            />
            <p className="text-xs text-gray-500 mt-1">0 for real-time streaming</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              x264 Preset
            </label>
            <select
              value={settings.x264Preset}
              onChange={(e) => handleSettingChange('x264Preset', e.target.value)}
              className="input-field"
            >
              <option value="ultrafast">Ultrafast</option>
              <option value="superfast">Superfast</option>
              <option value="veryfast">Veryfast</option>
              <option value="faster">Faster</option>
              <option value="fast">Fast</option>
            </select>
            <p className="text-xs text-gray-500 mt-1">Encoding speed vs quality</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              x264 Tune
            </label>
            <select
              value={settings.x264Tune}
              onChange={(e) => handleSettingChange('x264Tune', e.target.value)}
              className="input-field"
            >
              <option value="zerolatency">Zero Latency</option>
              <option value="fastdecode">Fast Decode</option>
              <option value="lowlatency">Low Latency</option>
            </select>
            <p className="text-xs text-gray-500 mt-1">Optimization for streaming</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              QR Display Duration (s)
            </label>
            <input
              type="number"
              value={settings.qrDuration}
              onChange={(e) => handleSettingChange('qrDuration', parseInt(e.target.value))}
              className="input-field"
              min="1"
              max="10"
            />
            <p className="text-xs text-gray-500 mt-1">How long to show QR code</p>
          </div>
        </div>
      </div>

      {/* Network Settings */}
      <div className="card">
        <div className="flex items-center space-x-2 mb-4">
          <Wifi className="h-5 w-5 text-sneakvlc-600" />
          <h2 className="text-lg font-semibold text-gray-900">Network Settings</h2>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Max Table Size
            </label>
            <input
              type="number"
              value={settings.maxTableSize}
              onChange={(e) => handleSettingChange('maxTableSize', parseInt(e.target.value))}
              className="input-field"
              min="5"
              max="50"
            />
            <p className="text-xs text-gray-500 mt-1">Maximum NAT punch entries</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Cleanup Interval (s)
            </label>
            <input
              type="number"
              value={settings.cleanupInterval}
              onChange={(e) => handleSettingChange('cleanupInterval', parseInt(e.target.value))}
              className="input-field"
              min="10"
              max="300"
            />
            <p className="text-xs text-gray-500 mt-1">How often to clean old entries</p>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="card">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button
              onClick={saveSettings}
              disabled={isSaving}
              className="btn-primary flex items-center space-x-2"
            >
              {isSaving ? (
                <RefreshCw className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              <span>{isSaving ? 'Saving...' : 'Save Settings'}</span>
            </button>

            <button
              onClick={resetSettings}
              className="btn-secondary flex items-center space-x-2"
            >
              <RefreshCw className="h-4 w-4" />
              <span>Reset to Defaults</span>
            </button>
          </div>

          {saveStatus && (
            <p className={`text-sm ${
              saveStatus.includes('successfully') ? 'text-green-600' : 'text-red-600'
            }`}>
              {saveStatus}
            </p>
          )}
        </div>
      </div>

      {/* System Info */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">System Information</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <p className="text-gray-600">Version</p>
            <p className="font-mono">1.0.0</p>
          </div>
          <div>
            <p className="text-gray-600">Build Date</p>
            <p className="font-mono">{new Date().toLocaleDateString()}</p>
          </div>
          <div>
            <p className="text-gray-600">Platform</p>
            <p className="font-mono">{navigator.platform}</p>
          </div>
          <div>
            <p className="text-gray-600">User Agent</p>
            <p className="font-mono text-xs truncate">{navigator.userAgent}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Settings 