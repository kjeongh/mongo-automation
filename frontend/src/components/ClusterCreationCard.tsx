import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Plus, Settings, Database, Shield, Monitor } from 'lucide-react'

export function ClusterCreationCard() {
  const [clusterType, setClusterType] = useState('')
  const [clusterName, setClusterName] = useState('')
  const [nodeCount, setNodeCount] = useState('')

  const handleCreateCluster = () => {
    console.log('Creating cluster:', { clusterType, clusterName, nodeCount })
  }

  return (
    <div className="space-y-6">
      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Database className="w-5 h-5 text-primary" />
              <div>
                <p className="text-sm text-gray-600">활성 클러스터</p>
                <p className="text-2xl font-bold">0</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Monitor className="w-5 h-5 text-blue-500" />
              <div>
                <p className="text-sm text-gray-600">모니터링</p>
                <p className="text-2xl font-bold">0</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Shield className="w-5 h-5 text-green-500" />
              <div>
                <p className="text-sm text-gray-600">보안 설정</p>
                <p className="text-2xl font-bold">0</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Settings className="w-5 h-5 text-orange-500" />
              <div>
                <p className="text-sm text-gray-600">자동화 작업</p>
                <p className="text-2xl font-bold">0</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Cluster Creation Card */}
      <Card className="border-2 border-dashed border-gray-200 hover:border-primary transition-colors">
        <CardHeader className="text-center">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mb-4">
            <Plus className="w-6 h-6 text-primary" />
          </div>
          <CardTitle className="text-2xl">새 MongoDB 클러스터 생성</CardTitle>
          <CardDescription className="text-lg">
            몇 분 안에 MongoDB 클러스터를 자동으로 구축하고 운영을 시작하세요
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">클러스터 타입</label>
              <Select value={clusterType} onValueChange={setClusterType}>
                <SelectTrigger>
                  <SelectValue placeholder="타입 선택" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="standalone">Standalone</SelectItem>
                  <SelectItem value="replicaset">Replica Set</SelectItem>
                  <SelectItem value="sharded">Sharded Cluster</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">클러스터 이름</label>
              <Input
                placeholder="my-mongodb-cluster"
                value={clusterName}
                onChange={(e) => setClusterName(e.target.value)}
              />
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">노드 수</label>
              <Select value={nodeCount} onValueChange={setNodeCount}>
                <SelectTrigger>
                  <SelectValue placeholder="노드 수" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">1 노드</SelectItem>
                  <SelectItem value="3">3 노드</SelectItem>
                  <SelectItem value="5">5 노드</SelectItem>
                  <SelectItem value="7">7 노드</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="border-t pt-6">
            <div className="flex flex-col md:flex-row gap-4 justify-between items-center">
              <div className="text-sm text-gray-600">
                <p>• 자동 모니터링 및 알림 설정</p>
                <p>• TLS 암호화 및 인증 구성</p>
                <p>• 일일 백업 스케줄 설정</p>
                <p>• 고가용성 보장</p>
              </div>
              
              <div className="flex gap-2">
                <Button variant="outline" size="lg">
                  고급 설정
                </Button>
                <Button 
                  size="lg"
                  onClick={handleCreateCluster}
                  disabled={!clusterType || !clusterName || !nodeCount}
                  className="bg-primary hover:bg-primary/90"
                >
                  <Plus className="w-4 h-4 mr-2" />
                  클러스터 생성
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}