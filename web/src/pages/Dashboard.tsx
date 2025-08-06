import { useState, useEffect } from 'react'
import { Activity, FileText, Users, Wifi, Clock, ArrowUpDown } from 'lucide-react'
import { useWebSocket } from '../contexts/WebSocketContext'

const Dashboard: React.FC = () => {
  const { isConnected, entries } = useWebSocket()
  const [stats, setStats] = useState({
    totalTransfers: 0,
    activeConnections: 0,
    totalFiles: 0,
    avgTransferTime: 0,
  })

  useEffect(() => {
    // Calculate stats from entries
    setStats({
      totalTransfers: entries.length,
      activeConnections: entries.filter(entry => 
        new Date(entry.last_seen).getTime() > Date.now() - 5 * 60 * 1000
      ).length,
      totalFiles: entries.length,
      avgTransferTime: entries.length > 0 ? 2.5 : 0, // Mock data
    })
  }, [entries])

  const recentActivity = entries.slice(0, 5).map(entry => ({
    id: entry.id,
    hash: entry.hash,
    ip: entry.ip,
    port: entry.port,
    timestamp: new Date(entry.created_at),
    type: 'transfer',
  }))

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600 mt-1">
          Overview of your SneakVLC P2P file transfer system
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="card">
          <div className="flex items-center">
            <div className="p-2 bg-sneakvlc-100 rounded-lg">
              <Activity className="h-6 w-6 text-sneakvlc-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total Transfers</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalTransfers}</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center">
            <div className="p-2 bg-green-100 rounded-lg">
              <Wifi className="h-6 w-6 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Active Connections</p>
              <p className="text-2xl font-bold text-gray-900">{stats.activeConnections}</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center">
            <div className="p-2 bg-blue-100 rounded-lg">
              <FileText className="h-6 w-6 text-blue-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Files Shared</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalFiles}</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Clock className="h-6 w-6 text-purple-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Avg Transfer Time</p>
              <p className="text-2xl font-bold text-gray-900">{stats.avgTransferTime}s</p>
            </div>
          </div>
        </div>
      </div>

      {/* Connection Status */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Connection Status</h2>
        <div className="flex items-center space-x-4">
          <div className={`status-indicator ${isConnected ? 'status-online' : 'status-offline'}`}>
            {isConnected ? 'Online' : 'Offline'}
          </div>
          <p className="text-sm text-gray-600">
            {isConnected 
              ? 'Connected to SneakVLC backend service'
              : 'Disconnected from backend service'
            }
          </p>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h2>
        {recentActivity.length > 0 ? (
          <div className="space-y-3">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <ArrowUpDown className="h-5 w-5 text-sneakvlc-600" />
                  <div>
                    <p className="text-sm font-medium text-gray-900">
                      File Transfer
                    </p>
                    <p className="text-xs text-gray-500">
                      {activity.ip}:{activity.port} • {activity.timestamp.toLocaleTimeString()}
                    </p>
                  </div>
                </div>
                <div className="text-xs text-gray-500">
                  {activity.timestamp.toLocaleDateString()}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8">
            <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500">No recent activity</p>
            <p className="text-sm text-gray-400 mt-1">
              Start sharing files to see activity here
            </p>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <button className="btn-primary flex items-center justify-center space-x-2">
            <ArrowUpDown className="h-5 w-5" />
            <span>Start Sending</span>
          </button>
          <button className="btn-secondary flex items-center justify-center space-x-2">
            <Download className="h-5 w-5" />
            <span>Start Receiving</span>
          </button>
        </div>
      </div>
    </div>
  )
}

export default Dashboard 