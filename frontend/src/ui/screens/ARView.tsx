import React, { useEffect, useRef, useState } from 'react';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import GlassCard from '../components/GlassCard';
import { useTranslation } from 'react-i18next';

type Point = { id:number; title:string; lat:number; lng:number };

function bearingBetween(lat1:number, lon1:number, lat2:number, lon2:number){
  const toRad = (d:number)=> d*Math.PI/180;
  const y = Math.sin(toRad(lon2-lon1))*Math.cos(toRad(lat2));
  const x = Math.cos(toRad(lat1))*Math.sin(toRad(lat2)) - Math.sin(toRad(lat1))*Math.cos(toRad(lat2))*Math.cos(toRad(lon2-lon1));
  return (Math.atan2(y,x)*180/Math.PI + 360) % 360;
}

export default function ARView(){
  const { t } = useTranslation();
  const videoRef = useRef<HTMLVideoElement>(null);
  const [heading, setHeading] = useState<number>(0);
  const [pos, setPos] = useState<{lat:number;lng:number} | null>(null);
  const [points, setPoints] = useState<Point[]>([]);

  useEffect(()=>{
    // camera
    (async ()=>{
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio:false });
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          await videoRef.current.play();
        }
      } catch(e){ console.warn('camera', e); }
    })();
    // position
    const geoId = navigator.geolocation.watchPosition(
      (p)=> setPos({lat:p.coords.latitude, lng:p.coords.longitude}),
      (e)=> console.warn('geo', e),
      { enableHighAccuracy: true }
    );
    // heading
    const handler = (ev: any)=> {
      const alpha = (ev.webkitCompassHeading ?? ev.alpha ?? 0);
      setHeading(alpha);
    };
    window.addEventListener('deviceorientationabsolute', handler, true);
    window.addEventListener('deviceorientation', handler, true);

    // demo points (could be fetched from API)
    setPoints([
      {id:1,title:'Spot A',lat:55.751, lng:37.62},
      {id:2,title:'Shop B',lat:55.752, lng:37.621},
      {id:3,title:'Slip C',lat:55.753, lng:37.618},
    ]);

    return ()=>{
      navigator.geolocation.clearWatch(geoId);
      window.removeEventListener('deviceorientationabsolute', handler, true);
      window.removeEventListener('deviceorientation', handler, true);
      if (videoRef.current?.srcObject){
        (videoRef.current.srcObject as MediaStream).getTracks().forEach(t=>t.stop());
      }
    };
  },[]);

  const overlays = points.slice(0,5).map(p=>{
    if (!pos) return null;
    const br = bearingBetween(pos.lat, pos.lng, p.lat, p.lng);
    const diff = ((br - heading + 540) % 360) - 180;
    const left = `calc(50% + ${diff*2}px)`; // 2px per degree
    return (
      <GlassCard key={p.id} style={{ position:'absolute', top: 24 + p.id*56, left, minWidth: 160 }}>
        <Typography variant="subtitle1">{p.title}</Typography>
      </GlassCard>
    );
  });

  return (
    <Box sx={{ position:'relative', height:'calc(100vh - 56px)' }}>
      <video ref={videoRef} style={{ position:'absolute', inset:0, width:'100%', height:'100%', objectFit:'cover' }} playsInline muted/>
      <Box sx={{ position:'absolute', top:8, left:8 }}>
        <GlassCard>
          <Typography variant="h6">{t('ar.title')} • {Math.round(heading)}°</Typography>
          {pos && <Typography variant="body2">{pos.lat.toFixed(4)}, {pos.lng.toFixed(4)}</Typography>}
        </GlassCard>
      </Box>
      {overlays}
      <Box sx={{ position:'absolute', bottom:16, left:16 }}>
        <Button variant="contained" href="/">{t('nav.map')}</Button>
      </Box>
    </Box>
  );
}
