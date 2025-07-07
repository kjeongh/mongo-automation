import { useState, useEffect } from 'react'

const words = ['구축', '관리', '배포', '운영', '최적화']

export function AnimatedTitle() {
  const [currentWordIndex, setCurrentWordIndex] = useState(0)
  const [isVisible, setIsVisible] = useState(true)

  useEffect(() => {
    const interval = setInterval(() => {
      setIsVisible(false)
      
      setTimeout(() => {
        setCurrentWordIndex((prev) => (prev + 1) % words.length)
        setIsVisible(true)
      }, 300)
    }, 3000)

    return () => clearInterval(interval)
  }, [])

  return (
    <h1 className="text-6xl md:text-7xl font-bold mb-6 text-primary">
      MongoDB 클러스터{' '}
      <span className={`inline-block transition-all duration-300 ${
        isVisible 
          ? 'opacity-100 transform translate-y-0' 
          : 'opacity-0 transform -translate-y-2'
      }`}>
        <span className="text-secondary">{words[currentWordIndex]}</span>
      </span>
      <br />
      플랫폼 MongoCraft
    </h1>
  )
}