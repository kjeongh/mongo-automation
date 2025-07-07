import { Header } from '@/components/Header'
import { ClusterCreationCard } from '@/components/ClusterCreationCard'

export function HomePage() {
  return (
    <div className="min-h-screen bg-white">
      <Header />
      
      {/* Hero Section - Clean and Modern */}
      <section className="bg-white py-24">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto text-center">
            {/* Main Title */}
            <h1 className="text-6xl md:text-7xl font-bold mb-6 text-primary">
              MongoCraft
            </h1>
            
            {/* Subtitle */}
            <p className="text-xl text-gray-600 max-w-2xl mx-auto mb-12 leading-relaxed">
              자동화된 MongoDB 클러스터 구축 및 운영 관리를 위한 통합 플랫폼
            </p>
                        
            {/* Feature Grid */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
              <div className="space-y-3">
                <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto">
                  <span className="text-2xl">⚡</span>
                </div>
                <h3 className="font-semibold text-gray-900">빠른 배포</h3>
                <p className="text-sm text-gray-600">몇 분 안에 클러스터 구축</p>
              </div>
              
              <div className="space-y-3">
                <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto">
                  <span className="text-2xl">🛡️</span>
                </div>
                <h3 className="font-semibold text-gray-900">자동 보안</h3>
                <p className="text-sm text-gray-600">TLS 암호화 및 인증</p>
              </div>
              
              <div className="space-y-3">
                <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto">
                  <span className="text-2xl">📊</span>
                </div>
                <h3 className="font-semibold text-gray-900">실시간 모니터링</h3>
                <p className="text-sm text-gray-600">성능 지표 추적</p>
              </div>
              
              <div className="space-y-3">
                <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto">
                  <span className="text-2xl">🔄</span>
                </div>
                <h3 className="font-semibold text-gray-900">자동 백업</h3>
                <p className="text-sm text-gray-600">데이터 안전성 보장</p>
              </div>
            </div>
          </div>
        </div>
      </section>
      
      <main className="bg-gray-50 py-16">
        <div className="container mx-auto px-4">        
          <div className="max-w-4xl mx-auto">
            <ClusterCreationCard />
          </div>
        </div>
      </main>
    </div>
  )
}