import React from 'react'
import mapboxgl, { Map } from 'mapbox-gl'
import { fetchMapPoints, addPointLocal } from '../data/api'

type Point = { id:number; title:string; lat:number; lng:number; type:string; is_featured:boolean; species?:string; weight?:number; length?:number }

const getProvider = () => (import.meta.env.VITE_MAP_PROVIDER || 'osm').toLowerCase()
const token = import.meta.env.VITE_MAPBOX_TOKEN?.trim()
if (getProvider()==='mapbox' && token) mapboxgl.accessToken = token

function toGeoJSON(points: Point[]) {
  return { type:'FeatureCollection', features: points.map(p=>({ type:'Feature', properties:{ id:p.id,title:p.title,type:p.type,is_featured:p.is_featured,species:p.species,weight:p.weight,length:p.length }, geometry:{ type:'Point', coordinates:[p.lng,p.lat] } })) } as GeoJSON.FeatureCollection
}

export default function MapboxMap({ filter, onMapClick }:{ filter?:{ types?:string[], featured?:boolean }, onMapClick?:(coords:{lng:number;lat:number})=>void }){
  const ref = React.useRef<HTMLDivElement|null>(null)
  const mapRef = React.useRef<Map|null>(null)
  const readyRef = React.useRef(false)
  const allPoints = React.useRef<Point[]>([])

  React.useEffect(()=>{
    if(!ref.current || mapRef.current) return
    const provider = getProvider()
    const style:any = (provider==='mapbox'&&token) ? 'mapbox://styles/mapbox/outdoors-v12' : { version:8, sources:{'osm-tiles':{type:'raster', tiles:['https://tile.openstreetmap.org/{z}/{x}/{y}.png'], tileSize:256, attribution:'© OpenStreetMap'}}, layers:[{id:'osm', type:'raster', source:'osm-tiles'}] }
    const m = new mapboxgl.Map({ container: ref.current, style, center:[37.62,55.75], zoom:9 })
    mapRef.current = m
    m.addControl(new mapboxgl.NavigationControl(), 'top-right')
    m.on('load', async ()=>{
      const pts = await fetchMapPoints()
      allPoints.current = pts
      const sourceId = 'points'
      m.addSource(sourceId, { type:'geojson', data: toGeoJSON(pts) as any, cluster:true, clusterMaxZoom:14, clusterRadius:50 } as any)

      // Layer styles by type
      m.addLayer({ id:'clusters', type:'circle', source:sourceId, filter:['has','point_count'],
        paint:{ 'circle-color':['step',['get','point_count'],'#87CEFA',20,'#1E90FF',50,'#104E8B'], 'circle-radius':['step',['get','point_count'],14,20,20,50,28] } })
      m.addLayer({ id:'cluster-count', type:'symbol', source:sourceId, filter:['has','point_count'], layout:{'text-field':['get','point_count_abbreviated'],'text-size':12}, paint:{'text-color':'#fff'} })
      m.addLayer({ id:'points', type:'circle', source:sourceId, filter:['!',['has','point_count']],
        paint:{
          'circle-color':[ 'case',
            ['==',['get','type'],'shop'], '#f59e0b',
            ['==',['get','type'],'slip'], '#10b981',
            ['==',['get','type'],'base'], '#8b5cf6',
            ['==',['get','type'],'catch'], '#ef4444',
            /* spot */ '#0E7490'
          ],
          'circle-radius':[ 'case', ['==',['get','is_featured'],true], 7, 6 ],
          'circle-stroke-width':2, 'circle-stroke-color':'#ffffff'
        }
      })

      m.on('click','points',(e)=>{
        const f = e.features && e.features[0]; if(!f) return
        const props:any = f.properties||{}; const coords = (f.geometry as any).coordinates?.slice()
        const fish = props.species ? `<br/>Вид: ${props.species}${props.weight?` • ${props.weight}кг`:''}${props.length?` • ${props.length}см`:''}` : ''
        new mapboxgl.Popup({offset:12}).setLngLat(coords).setHTML(`<strong>${props.title}</strong><br/>Тип: ${props.type}${fish}`).addTo(m)
      })

      m.on('click',(e)=>{ onMapClick?.({ lng: e.lngLat.lng, lat: e.lngLat.lat }) })

      readyRef.current = true
    })
  },[])

  // react to filter changes
  React.useEffect(()=>{
    const m = mapRef.current; if(!m || !readyRef.current) return
    const src = m.getSource('points') as any; if(!src?.setData) return
    const filtered = (allPoints.current||[]).filter(p=>{
      const okType = !filter?.types?.length || filter.types.includes(p.type)
      const okFeat = filter?.featured===undefined ? true : !!p.is_featured === !!filter.featured
      return okType && okFeat
    })
    src.setData(toGeoJSON(filtered) as any)
  },[filter])

  return <div className="map-wrap" ref={ref}/>
}
