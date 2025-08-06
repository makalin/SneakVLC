import { X, Home, Upload, Download, Settings, Wifi, WifiOff } from 'lucide-react'
import { Link, useLocation } from 'react-router-dom'
import { useWebSocket } from '../contexts/WebSocketContext'

interface SidebarProps {
  open: boolean
  onClose: () => void
}

const Sidebar: React.FC<SidebarProps> = ({ open, onClose }) => {
  const location = useLocation()
  const { isConnected } = useWebSocket()

  const navigation = [
    { name: 'Dashboard', href: '/', icon: Home },
    { name: 'Sender', href: '/sender', icon: Upload },
    { name: 'Receiver', href: '/receiver', icon: Download },
    { name: 'Settings', href: '/settings', icon: Settings },
  ]

  return (
    <>
      {/* Mobile backdrop */}
      {open && (
        <div
          className="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0
        ${open ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex items-center justify-between h-16 px-6 border-b border-gray-200">
          <h1 className="text-xl font-bold text-gray-900">
            <span className="text-gradient">SneakVLC</span>
          </h1>
          <button
            onClick={onClose}
            className="p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 lg:hidden"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        <div className="flex-1 flex flex-col overflow-y-auto">
          {/* Connection Status */}
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              {isConnected ? (
                <Wifi className="h-5 w-5 text-green-500" />
              ) : (
                <WifiOff className="h-5 w-5 text-red-500" />
              )}
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {isConnected ? 'Connected' : 'Disconnected'}
                </p>
                <p className="text-xs text-gray-500">
                  {isConnected ? 'Ready to transfer' : 'Check connection'}
                </p>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-6 py-4 space-y-2">
            {navigation.map((item) => {
              const isActive = location.pathname === item.href
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  onClick={onClose}
                  className={`
                    flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors duration-200
                    ${isActive
                      ? 'bg-sneakvlc-100 text-sneakvlc-700'
                      : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                    }
                  `}
                >
                  <item.icon className="mr-3 h-5 w-5" />
                  {item.name}
                </Link>
              )
            })}
          </nav>

          {/* Footer */}
          <div className="px-6 py-4 border-t border-gray-200">
            <p className="text-xs text-gray-500">
              P2P File Transfer via VLC
            </p>
            <p className="text-xs text-gray-400 mt-1">
              No Wi-Fi. No Cloud. Just Code and Light.
            </p>
          </div>
        </div>
      </div>
    </>
  )
}

export default Sidebar 