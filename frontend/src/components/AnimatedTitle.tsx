import { useState, useEffect } from 'react'

const words = ['Deploy', 'Monitoring', 'Optimize', 'Backup', 'Security']

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
    <h1 className="text-6xl md:text-7xl mb-6 text-left ml-8 md:ml-16">
      <span className="font-bold text-primary text-8xl md:text-7xl">MongoCraft:</span>
      <br />
      <span className="font-light text-gray-700 text-3xl md:text-4xl">Automated MongoDB Management for</span>{' '}
      <span className="inline-block px-4 py-1 rounded-xl border-2 border-gray-300 transition-all duration-300">
        <span className={`text-secondary text-4xl md:text-5xl transition-all duration-300 ${
          isVisible 
            ? 'opacity-100 transform translate-y-0' 
            : 'opacity-0 transform -translate-y-2'
        }`}>
          {words[currentWordIndex]}
        </span>
      </span>
    </h1>
  )
}