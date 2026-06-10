<template>
  <div class="relative w-full rounded overflow-hidden" :style="{ height: mapHeight }" ref="containerRef">
    <div :id="mapId" class="w-full h-full"></div>
    <!-- Usage Limit Warning -->
    <div v-if="!mapboxEnabled" class="absolute bottom-10 left-2 z-[1000] bg-white/90 px-2 py-1 rounded text-[10px] text-red-600 border border-red-200 shadow-sm backdrop-blur-sm">
      Đang dùng bản đồ thay thế (Hết lượt Mapbox hôm nay)
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, watch, shallowRef, ref } from 'vue';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useRouter } from 'vue-router';

const props = withDefaults(defineProps<{ 
  height?: string;
  stations?: any[];
  allStations?: any[];
  selectedProvince?: string;
  visible?: boolean;
  provinceList?: string[];
}>(), { 
  height: '100%',
  stations: () => [],
  allStations: () => [],
  selectedProvince: '',
  visible: true,
  provinceList: () => [],
});

const emit = defineEmits<{
  (e: 'station-click', station: any): void;
  (e: 'province-select', province: string): void;
}>();

const router = useRouter();
const mapHeight = props.height;
const mapId = `map-${Math.random().toString(36).slice(2, 8)}`;
const containerRef = ref<HTMLDivElement | null>(null);

const mapRef = shallowRef<L.Map | null>(null);
const markersLayer = shallowRef<L.LayerGroup | null>(null);
const provincesGeoLayer = shallowRef<L.GeoJSON | null>(null);
const mapboxEnabled = ref(true);

// Vietnam geographic constants
const VN_CENTER: [number, number] = [16.0, 108.5];
const VN_BOUNDS = L.latLngBounds([7.0, 102.0], [24.0, 116.0]);

// ── Dot size by zoom level ──
function getDotSize(zoom: number): number {
  if (zoom <= 6)  return 12;
  if (zoom <= 8)  return 16;
  if (zoom <= 10) return 22;
  return 28;
}

// ── Connect status helpers ──
function connectStatusLabel(cs?: number): string {
  if (cs === 1) return '🟢 Online';
  if (cs === 2) return '🟡 No data';
  if (cs === 3) return '🔴 Offline';
  return '—';
}
function connectStatusColor(cs?: number): string {
  if (cs === 1) return '#16a34a'; // green-600
  if (cs === 2) return '#d97706'; // amber-600
  return '#dc2626'; // red-600
}

// ── Fullscreen icons ──
const iconExpand = `<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/></svg>`;
const iconCompress = `<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 14 10 14 10 20"/><polyline points="20 10 14 10 14 4"/><line x1="10" y1="14" x2="3" y2="21"/><line x1="21" y1="3" x2="14" y2="10"/></svg>`;

onMounted(async () => {
  // ── Usage Tracking ──
  const today = new Date().toISOString().split('T')[0] || '';
  const lastDate = localStorage.getItem('mapbox_usage_date');
  let count = Number(localStorage.getItem('mapbox_usage_count') || 0);
  const limit = Number(import.meta.env.VITE_MAPBOX_DAILY_LIMIT) || 1000;

  if (lastDate !== today) {
    count = 0;
    localStorage.setItem('mapbox_usage_date', today);
  }
  if (count >= limit) {
    mapboxEnabled.value = false;
  } else {
    count++;
    localStorage.setItem('mapbox_usage_count', String(count));
    mapboxEnabled.value = true;
  }

  const map = L.map(mapId, {
    center: VN_CENTER,
    zoom: 6,
    maxBounds: VN_BOUNDS,
    maxBoundsViscosity: 1.0,
    minZoom: 5.5,
    maxZoom: 18,
    zoomControl: true,
    attributionControl: false, // Ngăn chặn dòng chữ "Leaflet"
  });
  mapRef.value = map;

  if (props.visible) {
    map.flyToBounds(VN_BOUNDS, { padding: [5, 5], duration: 1 });
  }
  markersLayer.value = L.layerGroup().addTo(map);

  // ── Base Layers ──
  const terrainLayer = L.tileLayer(
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    { attribution: 'Tiles &copy; Esri' }
  );

  const mapboxToken = import.meta.env.VITE_MAPBOX_TOKEN || '';
  let satelliteLayer: L.TileLayer | undefined;
  let darkLayer: L.TileLayer | undefined;
  let outdoorsLayer: L.TileLayer | undefined;

  if (mapboxEnabled.value && mapboxToken) {
    satelliteLayer = L.tileLayer(
      `https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{z}/{x}/{y}?access_token=${mapboxToken}`,
      { attribution: '© Mapbox' }
    );
    darkLayer = L.tileLayer(
      `https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=${mapboxToken}`,
      { attribution: '© Mapbox' }
    );
    outdoorsLayer = L.tileLayer(
      `https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/{z}/{x}/{y}?access_token=${mapboxToken}`,
      { attribution: '© Mapbox' }
    );
  }

  if (satelliteLayer) {
    satelliteLayer.addTo(map);
  } else {
    terrainLayer.addTo(map);
  }

  // ── Island Labels ──
  const islandLabels = [
    { pos: [10.823111, 106.629647] as [number, number], text: 'TP. Hồ Chí Minh' },
    { pos: [21.027812, 105.834535] as [number, number], text: 'Hà Nội' },
    { pos: [16.5839161, 112.4743021] as [number, number], text: 'Quần đảo<br/>Hoàng Sa' },
    { pos: [10.6921803, 115.7505101] as [number, number], text: 'Quần đảo<br/>Trường Sa' },
  ];
  islandLabels.forEach(label => {
    L.marker(label.pos, {
      icon: L.divIcon({ className: 'island-label', html: `<div>${label.text}</div>`, iconSize: [120, 40], iconAnchor: [60, 20] }),
      interactive: false,
    }).addTo(map);
  });

  // ── Overlay: Provinces ──
  try {
    const res = await fetch('/data/vietnam_provinces.geojson');
    const geoData = await res.json();
    provincesGeoLayer.value = L.geoJSON(geoData, {
      style: () => ({ color: '#ffffff', weight: 1.5, fillColor: '#3498db', fillOpacity: 0.1 }),
      onEachFeature: (feature: any, layer: any) => {
        const name = feature.properties?.adm1_name1 || feature.properties?.adm1_name || '';
        layer.provinceName = name;
        if (name) layer.bindTooltip(name, { sticky: true, className: 'province-tooltip' });
        layer.on({
          mouseover: (e: any) => e.target.setStyle({ fillOpacity: 0.35, weight: 2.5, color: '#f39c12' }),
          mouseout: (e: any) => {
            if (props.selectedProvince !== name) provincesGeoLayer.value?.resetStyle(e.target);
          },
          click: (e: any) => {
            const pname = e.target.provinceName;
            const dataToCount = props.allStations && props.allStations.length > 0 ? props.allStations : props.stations;
            const cnt = dataToCount.filter((s: any) => s.province === pname).length;
            L.popup()
              .setLatLng(e.latlng)
              .setContent(`<div style="font-family:inherit;padding:2px;"><b style="font-size:14px;color:#2c3e50;">${pname}</b><br/><span style="font-size:12px;color:#666;">Số lượng trạm: <b>${cnt}</b></span></div>`)
              .openOn(map);
          },
        });
      },
    }).addTo(map);
    highlightProvince(props.selectedProvince);
  } catch { /* provinces optional */ }

  // ── Layer Control ──
  const baseMaps: Record<string, L.TileLayer> = {};
  if (satelliteLayer) baseMaps['Vệ tinh (Mapbox)'] = satelliteLayer;
  if (darkLayer)     baseMaps['Giao diện Tối (Mapbox)'] = darkLayer;
  if (outdoorsLayer) baseMaps['Ngoài trời (Mapbox)'] = outdoorsLayer;
  baseMaps['Địa hình (Esri)'] = terrainLayer;
  
  const overlays: Record<string, L.Layer> = {};
  if (provincesGeoLayer.value) overlays['Ranh giới tỉnh'] = provincesGeoLayer.value;
  L.control.layers(baseMaps, overlays, { position: 'topright' }).addTo(map);

  // ── Zoom re-render markers ──
  map.on('zoomend', () => renderMarkers());

  // ────────────────────────────────────────────────
  // CUSTOM CONTROL: Fullscreen
  // ────────────────────────────────────────────────
  const FullscreenControl = L.Control.extend({
    options: { position: 'topleft' },
    onAdd() {
      const btn = L.DomUtil.create('button', 'map-ctrl-btn map-ctrl-fullscreen') as HTMLButtonElement;
      btn.title = 'Toàn màn hình';
      btn.innerHTML = iconExpand;
      L.DomEvent.disableClickPropagation(btn);
      L.DomEvent.on(btn, 'click', () => {
        const el = containerRef.value;
        if (!el) return;
        if (!document.fullscreenElement) {
          el.requestFullscreen();
          btn.innerHTML = iconCompress;
          btn.title = 'Thoát toàn màn hình';
        } else {
          document.exitFullscreen();
          btn.innerHTML = iconExpand;
          btn.title = 'Toàn màn hình';
        }
      });
      document.addEventListener('fullscreenchange', () => {
        if (!document.fullscreenElement) {
          btn.innerHTML = iconExpand;
          btn.title = 'Toàn màn hình';
        }
      });
      return btn;
    },
  });
  new FullscreenControl().addTo(map);

  // ────────────────────────────────────────────────
  // CUSTOM CONTROL: Danh sách trạm
  // ────────────────────────────────────────────────
  const StationListControl = L.Control.extend({
    options: { position: 'bottomleft' },
    onAdd() {
      const btn = L.DomUtil.create('button', 'map-ctrl-btn map-ctrl-icon-only map-ctrl-list') as HTMLButtonElement;
      btn.title = 'Danh sách trạm';
      btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>`;
      L.DomEvent.disableClickPropagation(btn);
      L.DomEvent.on(btn, 'click', () => router.push('/stations'));
      return btn;
    },
  });
  new StationListControl().addTo(map);

  // ────────────────────────────────────────────────
  // CUSTOM CONTROL: Các tỉnh
  // ────────────────────────────────────────────────
  const ProvincesControl = L.Control.extend({
    options: { position: 'bottomleft' },
    onAdd() {
      const wrap = L.DomUtil.create('div', 'map-provinces-wrap');
      L.DomEvent.disableClickPropagation(wrap);
      L.DomEvent.disableScrollPropagation(wrap);

      const btn = L.DomUtil.create('button', 'map-ctrl-btn map-ctrl-icon-only map-ctrl-provinces', wrap) as HTMLButtonElement;
      btn.title = 'Chọn tỉnh / thành phố';
      btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>`;

      const panel = L.DomUtil.create('div', 'map-prov-panel', wrap);
      const searchInput = L.DomUtil.create('input', 'map-prov-search', panel) as HTMLInputElement;
      searchInput.type = 'text';
      searchInput.placeholder = '🔍 Tìm tỉnh...';
      const listEl = L.DomUtil.create('div', 'map-prov-list', panel);

      const buildList = (keyword: string) => {
        listEl.innerHTML = '';
        const allItem = L.DomUtil.create('div', 'map-prov-item map-prov-all', listEl);
        allItem.innerHTML = '🗺️&nbsp;Tất cả Việt Nam';
        allItem.addEventListener('click', () => {
          emit('province-select', '');
          panel.classList.remove('open');
        });

        const source = props.provinceList.length > 0
          ? props.provinceList
          : Array.from(new Set(props.stations.map((s: any) => s.province).filter(Boolean))).sort() as string[];

        source
          .filter(p => p.toLowerCase().includes(keyword.toLowerCase()))
          .forEach(p => {
            const dataToCount = props.allStations && props.allStations.length > 0 ? props.allStations : props.stations;
            const cnt = dataToCount.filter((s: any) => s.province === p).length;
            const isActive = (p === props.selectedProvince);
            const item = L.DomUtil.create('div', `map-prov-item ${isActive ? 'active' : ''}`, listEl);
            item.innerHTML = `<span>${p}</span><span class="map-prov-badge">${cnt}</span>`;
            item.addEventListener('click', () => {
              emit('province-select', p);
              panel.classList.remove('open');
            });
          });
      };

      searchInput.addEventListener('input', () => buildList(searchInput.value));

      let hideTimeout: any = null;

      wrap.addEventListener('mouseenter', () => {
        clearTimeout(hideTimeout);
        if (!panel.classList.contains('open')) {
          buildList(searchInput.value);
          panel.classList.add('open');
        }
      });

      wrap.addEventListener('mouseleave', () => {
        // Do not hide if the user is typing in the search box
        if (document.activeElement === searchInput) return;
        
        hideTimeout = setTimeout(() => {
          panel.classList.remove('open');
        }, 200);
      });

      searchInput.addEventListener('blur', () => {
        if (!wrap.matches(':hover')) {
          panel.classList.remove('open');
        }
      });

      btn.addEventListener('click', () => {
        searchInput.focus();
      });
      return wrap;
    },
  });
  new ProvincesControl().addTo(map);

  // Initial markers render
  renderMarkers();
});

// ────────────────────────────────────────────────
// RENDER MARKERS (recalc dot sizes based on zoom)
// ────────────────────────────────────────────────
function renderMarkers() {
  if (!mapRef.value || !markersLayer.value) return;
  markersLayer.value.clearLayers();

  const zoom = mapRef.value.getZoom();
  const size = getDotSize(zoom);
  const border = size >= 20 ? 3 : 2;
  const glow = Math.round(size * 0.55);

  props.stations.forEach((s: any) => {
    if (!s.lat || !s.lng) return;

    const isActive = s.status === 1;
    const dotColor = isActive ? '#22C55E' : '#EF4444';
    const csColor  = connectStatusColor(s.connectStatus);

    const icon = L.divIcon({
      html: `<div style="
        width:${size}px;height:${size}px;border-radius:50%;
        background:radial-gradient(circle at 35% 35%, ${dotColor}ee, ${dotColor}bb);
        border:${border}px solid rgba(255,255,255,0.92);
        box-shadow:0 0 ${glow}px ${dotColor}88, 0 2px 5px rgba(0,0,0,0.28);
        cursor:pointer;transition:transform .15s;
      "></div>`,
      className: 'station-dot-wrap',
      iconSize:   [size, size],
      iconAnchor: [size / 2, size / 2],
    });

    const popup = `
      <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;min-width:230px;padding:2px 0;">
        <div style="display:flex;align-items:center;gap:8px;padding-bottom:9px;margin-bottom:9px;border-bottom:1px solid #eee;">
          <span style="width:10px;height:10px;border-radius:50%;background:${dotColor};box-shadow:0 0 5px ${dotColor};flex-shrink:0;"></span>
          <b style="font-size:14px;color:#1a1a2e;">${s.stationName || s.name || '—'}</b>
        </div>
        <table style="width:100%;font-size:12px;border-collapse:collapse;line-height:1.8;">
          <tr><td style="color:#888;width:95px;">ID</td><td style="font-weight:700;font-family:monospace;color:#2c3e50;">${s.id}</td></tr>
          ${s.identificationName ? `<tr><td style="color:#888;">Tên hiển thị</td><td style="color:#2c3e50;">${s.identificationName}</td></tr>` : ''}
          ${s.province ? `<tr><td style="color:#888;">Tỉnh/TP</td><td style="color:#2c3e50;">${s.province}</td></tr>` : ''}
          <tr><td style="color:#888;">Trạng thái</td><td style="color:${dotColor};font-weight:600;">${isActive ? '🟢 Đang chạy' : '🔴 Dừng'}</td></tr>
          <tr><td style="color:#888;">Kết nối</td><td style="color:${csColor};font-weight:600;">${connectStatusLabel(s.connectStatus)}</td></tr>
          ${s.receiverType ? `<tr><td style="color:#888;">Receiver</td><td style="color:#2c3e50;">${s.receiverType}</td></tr>` : ''}
          ${s.antennaType ? `<tr><td style="color:#888;">Antenna</td><td style="color:#2c3e50;">${s.antennaType}</td></tr>` : ''}
          <tr>
            <td style="color:#888;vertical-align:top;">Toạ độ</td>
            <td style="color:#2c3e50;font-family:monospace;font-size:11px;">${s.lat?.toFixed(6)}<br/>${s.lng?.toFixed(6)}</td>
          </tr>
          ${s.updatedAt ? `<tr><td style="color:#888;">Cập nhật</td><td style="color:#999;font-size:11px;">${new Date(s.updatedAt).toLocaleString('vi-VN')}</td></tr>` : ''}
        </table>
        <div style="margin-top:9px;padding-top:8px;border-top:1px solid #eee;text-align:center;font-size:11px;color:#aaa;">Nhấn vào để xem thêm chi tiết trong bảng bên phải</div>
      </div>`;

    L.marker([s.lat, s.lng], { icon })
      .addTo(markersLayer.value!)
      .bindPopup(popup, { maxWidth: 290, className: 'station-popup' })
      .on('click', () => emit('station-click', s));
  });
}

function highlightProvince(provinceName: string) {
  if (!mapRef.value || !provincesGeoLayer.value) return;
  
  provincesGeoLayer.value.setStyle({ color: '#ffffff', weight: 1.5, fillColor: '#3498db', fillOpacity: 0.1 });

  if (!provinceName) {
    mapRef.value.flyToBounds(VN_BOUNDS, { duration: 1 });
    return;
  }

  let foundLayer: any = null;
  provincesGeoLayer.value.eachLayer((layer: any) => {
    if (layer.provinceName === provinceName) foundLayer = layer;
  });

  if (foundLayer) {
    foundLayer.setStyle({ fillOpacity: 0.3, fillColor: '#f39c12', weight: 3, color: '#d35400' });
    mapRef.value.flyToBounds(foundLayer.getBounds(), { padding: [20, 20], duration: 1.5 });
  }
}

watch(() => props.stations, () => renderMarkers(), { deep: true });
watch(() => props.selectedProvince, (newVal) => highlightProvince(newVal));
watch(() => props.visible, (newVal) => {
  if (newVal && mapRef.value) {
    setTimeout(() => {
      mapRef.value?.invalidateSize();
      if (!props.selectedProvince) {
        mapRef.value?.flyToBounds(VN_BOUNDS, { duration: 1 });
      } else {
        highlightProvince(props.selectedProvince);
      }
    }, 100);
  }
});

onUnmounted(() => {
  if (mapRef.value) {
    mapRef.value.remove();
    mapRef.value = null;
  }
});
</script>

<style scoped>
[id^="map-"] { background-color: #e9ecef; }
</style>
<style>
/* ── Tooltips & Labels ── */
.province-tooltip { font-size: 13px; font-weight: 600; padding: 4px 10px; border-radius: 4px; }
.island-label { background: none !important; border: none !important; padding: 0 !important; }
.island-label div {
  color: #ffeb3b; 
  text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000, 0 0 8px rgba(0,0,0,0.8);
  font-size: 13px; font-weight: bold; text-align: center; line-height: 1.2; white-space: nowrap;
}

/* ── Markers ── */
.station-dot-wrap > div:hover { transform: scale(1.35) !important; }
.station-popup .leaflet-popup-content-wrapper { border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.15); padding: 0; overflow: hidden; }
.station-popup .leaflet-popup-content { margin: 13px 15px; }

/* ── Custom Controls ── */
.map-ctrl-btn {
  display: inline-flex; align-items: center; gap: 5px;
  background: #fff; color: #2d3748;
  border: none; border-radius: 7px;
  padding: 7px 12px; font-size: 12px; font-weight: 600;
  cursor: pointer; box-shadow: 0 2px 8px rgba(0,0,0,0.18);
  transition: all .14s ease;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  white-space: nowrap; line-height: 1;
}
.map-ctrl-btn:hover { background: #eff6ff; color: #2563eb; box-shadow: 0 4px 14px rgba(37,99,235,0.22); transform: translateY(-1px); }
.map-ctrl-btn:active { transform: translateY(0); }
.map-ctrl-fullscreen, .map-ctrl-icon-only { width: 34px; height: 34px; padding: 0; justify-content: center; }

/* Leaflet control placement adjusments */
.leaflet-bottom.leaflet-left .leaflet-control { margin-bottom: 6px !important; margin-left: 10px !important; }

/* ── Provinces Panel ── */
.map-provinces-wrap { position: relative; }
.map-prov-panel {
  display: none; position: absolute; bottom: calc(100% + 6px); left: 0;
  width: 224px; background: #fff; border-radius: 10px;
  box-shadow: 0 8px 28px rgba(0,0,0,0.18); overflow: hidden; z-index: 9999;
}
.map-prov-panel.open { display: block; animation: prov-slide .15s ease; }
@keyframes prov-slide { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
.map-prov-search { width: 100%; box-sizing: border-box; padding: 10px 12px; border: none; border-bottom: 1px solid #eee; font-size: 13px; outline: none; background: #f8f9fb; }
.map-prov-search:focus { background: #fff; border-bottom-color: #3b82f6; }
.map-prov-list { max-height: 248px; overflow-y: auto; padding: 4px 0; }
.map-prov-list::-webkit-scrollbar { width: 4px; }
.map-prov-list::-webkit-scrollbar-thumb { background: #ddd; border-radius: 2px; }
.map-prov-item { display: flex; justify-content: space-between; align-items: center; padding: 8px 14px; font-size: 13px; cursor: pointer; color: #333; transition: background .1s; }
.map-prov-item:hover { background: #eff6ff; color: #2563eb; }
.map-prov-item.active { background: #eff6ff; color: #2563eb; font-weight: 600; }
.map-prov-all { color: #555; font-style: italic; }
.map-prov-badge { background: #e0e7ff; color: #3730a3; border-radius: 10px; padding: 1px 8px; font-size: 11px; font-weight: 700; }
.map-prov-item.active .map-prov-badge { background: #dbeafe; color: #1e40af; }

/* ── Fullscreen state ── */
:fullscreen .w-full.h-full, :-webkit-full-screen .w-full.h-full { height: 100vh !important; }

/* ── Focus Outline Fix ── */
.leaflet-interactive:focus, path.leaflet-interactive:focus { outline: none !important; }
</style>
