import { Database } from 'lucide-react'

export function Header() {
  return (
    <header className="bg-white shadow-sm border-b">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <Database className="w-5 h-5 text-white" />
            </div>
            <h1 className="text-xl font-bold text-gray-900">MongoCraft</h1>
          </div>
          
          <nav className="hidden md:flex space-x-6">
            <a href="#" className="text-gray-600 hover:text-primary transition-colors">
              클러스터 관리
            </a>
            <a href="#" className="text-gray-600 hover:text-primary transition-colors">
              모니터링
            </a>
            <a href="#" className="text-gray-600 hover:text-primary transition-colors">
              백업
            </a>
            <a href="#" className="text-gray-600 hover:text-primary transition-colors">
              설정
            </a>
          </nav>
        </div>
      </div>
    </header>
  )
}