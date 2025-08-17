import React from 'react'
import { Box, Typography } from '@mui/material'

declare global {
  interface DeviceOrientationEvent { webkitCompassHeading?: number }
}

export default function ARScreen(){
  const videoRef = React.useRef<HTMLVideoElement|null>(null)
  const [heading, setHeading] = React.useState(0)

  React.useEffect(()=>{
    const init = async ()=>{
      try{
        const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio:false })
        if(videoRef.current){ videoRef.current.srcObject = stream; await videoRef.current.play() }
      }catch(e){ console.warn('Camera error', e) }
    }
    init()
    const onOrient = (e: DeviceOrientationEvent)=>{
      const alpha = (e.webkitCompassHeading as any) || e.alpha || 0
      setHeading(Math.round(alpha))
    }
    window.addEventListener('deviceorientation', onOrient, true)
    return ()=> window.removeEventListener('deviceorientation', onOrient, true)
  },[])

  return (
    <Box sx={{ position:'relative', height:'70vh', borderRadius:2, overflow:'hidden', background:'#000' }}>
      <video ref={videoRef} playsInline muted style={{ width:'100%', height:'100%', objectFit:'cover' }} />
      <Box sx={{ position:'absolute', top:16, left:16, px:2, py:1, bgcolor:'rgba(0,0,0,0.5)', color:'#fff', borderRadius:2 }}>
        <Typography variant="body2">Heading: {heading}°</Typography>
        <Typography variant="caption">AR-режим (демо): компас + камера</Typography>
      </Box>
    </Box>
  )
}
