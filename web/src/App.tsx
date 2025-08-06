import { Routes, Route } from 'react-router-dom'
import { useState, useEffect } from 'react'
import Header from './components/Header'
import Sidebar from './components/Sidebar'
import Dashboard from './pages/Dashboard'
import Sender from './pages/Sender'
import Receiver from './pages/Receiver'
import Settings from './pages/Settings'
import { WebSocketProvider } from './contexts/WebSocketContext'

function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false)

  return (
    <WebSocketProvider>
      <div className="min-h-screen bg-gray-50">
        <Header onMenuClick={() => setSidebarOpen(true)} />
        
        <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        
        <main className="lg:pl-64">
          <div className="px-4 py-8 sm:px-6 lg:px-8">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/sender" element={<Sender />} />
              <Route path="/receiver" element={<Receiver />} />
              <Route path="/settings" element={<Settings />} />
            </Routes>
          </div>
        </main>
      </div>
    </WebSocketProvider>
  )
}

export default App 