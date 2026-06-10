<template>
  <div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden relative">
      <div class="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50 flex-wrap gap-4">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <span class="font-bold text-gray-700">📍 Bản đồ Trạm CORS {{ selectedProvince ? ` - ${selectedProvince}` : '' }}</span>
            <el-tag type="info" size="small">{{ filteredStations.length }} trạm</el-tag>
          </div>
          <el-button 
            size="small" 
            :type="showMap ? 'info' : 'primary'" 
            link 
            class="lg:!hidden"
            @click="showMap = !showMap"
          >
            <el-icon :size="18">
              <View v-if="!showMap" />
              <Hide v-else />
            </el-icon>
          </el-button>
        </div>

        <div class="flex items-center gap-3">
          <el-select
            v-model="selectedProvince"
            placeholder="Lọc theo Tỉnh"
            clearable
            filterable
            class="w-48"
            size="small"
          >
            <el-option label="Tất cả (Việt Nam)" value="" />
            <el-option
              v-for="prov in provinceList"
              :key="prov"
              :label="prov"
              :value="prov"
            />
          </el-select>
          <el-button size="small" @click="$router.push('/stations')">📋 Danh sách</el-button>
        </div>
      </div>

      <div class="relative station-map" :class="{'map-hidden': !showMap, 'map-visible': showMap}">
        <!-- Hidden map placeholder -->
        <div v-if="!showMap" class="flex flex-col items-center justify-center py-12 bg-gray-50 italic text-gray-400 absolute inset-0 z-10 hidden-placeholder">
          <el-icon :size="40" class="mb-3"><View /></el-icon>
          <p class="text-center px-4">Bản đồ đang được ẩn để tối ưu không gian. <br/> Nhấn icon hiển thị phía trên để xem bản đồ.</p>
        </div>
        <div v-show="showMap" class="absolute inset-0 z-0">
          <div v-if="mapLoading" class="absolute inset-0 bg-white/50 backdrop-blur-sm z-10 flex items-center justify-center h-full">
            <el-icon class="is-loading text-3xl text-blue-500"><Loading /></el-icon>
          </div>
          <MapComponent 
            :stations="filteredStations" 
            :allStations="_allStations"
            :selectedProvince="selectedProvince"
            :visible="showMap"
            :provinceList="provinceList"
            height="100%" 
            @station-click="openStationDetails"
            @province-select="onProvinceSelect"
          />
        </div>
      </div>
    </div>

    <!-- Station Details Drawer -->
    <el-drawer
      v-model="drawerVisible"
      :title="selectedStation?.stationName || 'Chi tiết trạm'"
      size="440px"
      destroy-on-close
    >
      <div v-if="selectedStation" class="flex flex-col gap-5">

        <!-- Status Header -->
        <div
          class="flex items-center gap-4 p-4 rounded-xl border"
          :class="selectedStation.status === 1 ? 'bg-green-50 border-green-100' : 'bg-red-50 border-red-100'"
        >
          <div
            class="w-14 h-14 rounded-full flex items-center justify-center text-2xl shadow flex-shrink-0"
            :class="selectedStation.status === 1 ? 'bg-green-500' : 'bg-red-500'"
          >📡</div>
          <div class="flex-1 min-w-0">
            <h3 class="font-bold text-lg text-gray-800 truncate">{{ selectedStation.stationName }}</h3>
            <div v-if="selectedStation.identificationName" class="text-sm text-gray-500 truncate">
              {{ selectedStation.identificationName }}
            </div>
            <div class="flex flex-wrap gap-2 mt-1.5">
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="selectedStation.status === 1 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'"
              >{{ selectedStation.status === 1 ? '🟢 Đang hoạt động' : '🔴 Dừng hoạt động' }}</span>
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="connectStatusClass(selectedStation.connectStatus)"
              >{{ connectStatusLabel(selectedStation.connectStatus) }}</span>
            </div>
          </div>
        </div>

        <!-- Info rows -->
        <div class="rounded-xl border border-gray-100 overflow-hidden divide-y divide-gray-100">
          <div v-for="row in infoRows" :key="row.label" class="flex items-start gap-3 px-4 py-3">
            <span class="text-base w-5 flex-shrink-0 mt-0.5">{{ row.icon }}</span>
            <div class="flex-1 min-w-0">
              <div class="text-[11px] text-gray-400 uppercase tracking-wide mb-0.5">{{ row.label }}</div>
              <div class="text-sm font-medium text-gray-800 break-all" :class="row.mono ? 'font-mono' : ''">
                {{ row.value || '—' }}
              </div>
            </div>
          </div>
        </div>

        <!-- Coordinates -->
        <div class="bg-blue-50 border border-blue-100 rounded-xl p-4">
          <div class="text-[11px] text-blue-400 uppercase tracking-wide mb-2">📌 Toạ độ địa lý</div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <div class="text-xs text-gray-500 mb-1">Vĩ độ (Latitude)</div>
              <div class="font-mono font-semibold text-sm text-gray-800">{{ selectedStation.lat?.toFixed(6) || '—' }}</div>
            </div>
            <div>
              <div class="text-xs text-gray-500 mb-1">Kinh độ (Longitude)</div>
              <div class="font-mono font-semibold text-sm text-gray-800">{{ selectedStation.lng?.toFixed(6) || '—' }}</div>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex gap-2">
          <el-button type="primary" class="flex-1" @click="$router.push('/stations')">
            📋 Xem trong danh sách
          </el-button>
          <el-button @click="copyCoords" title="Copy toạ độ">
            📋 Copy toạ độ
          </el-button>
        </div>

        <!-- Updated at -->
        <div v-if="selectedStation.updatedAt" class="text-center text-xs text-gray-400">
          Cập nhật lần cuối: {{ new Date(selectedStation.updatedAt).toLocaleString('vi-VN') }}
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue';
import { ElMessage } from 'element-plus';
import MapComponent from '../../components/MapComponent.vue';
import { stationApi } from '../../services/api';
import { Loading, View, Hide } from '@element-plus/icons-vue';
import * as turf from '@turf/turf';

const _allStations = ref<any[]>([]);
const provinceList  = ref<string[]>([]);
const selectedProvince = ref('');
const mapLoading = ref(true);
const showMap = ref(window.innerWidth > 1024);

const drawerVisible   = ref(false);
const selectedStation = ref<any>(null);

const filteredStations = computed(() =>
  selectedProvince.value
    ? _allStations.value.filter(s => s.province === selectedProvince.value)
    : _allStations.value
);

// ── Connect status ──
function connectStatusLabel(cs?: number): string {
  if (cs === 1) return '🟢 Online';
  if (cs === 2) return '🟡 No data';
  if (cs === 3) return '🔴 Offline';
  return '⚪ Không rõ';
}
function connectStatusClass(cs?: number): string {
  if (cs === 1) return 'bg-green-100 text-green-700';
  if (cs === 2) return 'bg-yellow-100 text-yellow-700';
  if (cs === 3) return 'bg-red-100 text-red-700';
  return 'bg-gray-100 text-gray-500';
}

// ── Drawer info rows (dynamic, filters out empty values) ──
const infoRows = computed(() => {
  const s = selectedStation.value;
  if (!s) return [];
  return [
    { icon: '🆔', label: 'Mã Trạm (ID)',              value: s.id != null ? String(s.id) : '',  mono: true  },
    { icon: '🏷️', label: 'Tên hiển thị (Identification)', value: s.identificationName,            mono: false },
    { icon: '📍', label: 'Tỉnh / Thành phố',           value: s.province,                        mono: false },
    { icon: '📻', label: 'Thiết bị thu (Receiver)',     value: s.receiverType,                    mono: false },
    { icon: '📡', label: 'Ăng-ten (Antenna)',            value: s.antennaType,                     mono: false },
    { icon: '💾', label: 'Firmware / Phiên bản',        value: s.firmwareVersion || s.version,    mono: true  },
    { icon: '🌐', label: 'Địa chỉ IP',                  value: s.ip || s.ipAddress,               mono: true  },
    { icon: '🔌', label: 'Port',                        value: s.port != null ? String(s.port) : '', mono: true },
  ].filter(r => r.value);
});

function copyCoords() {
  const s = selectedStation.value;
  if (!s) return;
  const text = `${s.lat?.toFixed(6)}, ${s.lng?.toFixed(6)}`;
  navigator.clipboard.writeText(text).then(() => ElMessage.success('Đã copy: ' + text));
}

async function loadData() {
  mapLoading.value = true;
  try {
    let geoFeatures: any[] = [];
    try {
      const gRes  = await fetch('/data/vietnam_provinces.geojson');
      const gData = await gRes.json();
      geoFeatures = gData.features || [];
      const pSet  = new Set<string>();
      geoFeatures.forEach(f => {
        const name = f.properties?.adm1_name1 || f.properties?.adm1_name;
        if (name) pSet.add(name);
      });
      provinceList.value = Array.from(pSet).sort();
    } catch { console.warn('Could not load geojson for provinces'); }

    const res        = await stationApi.getStations({ page: 1, size: 2000 });
    const rawStations = res.data?.records || [];

    rawStations.forEach((s: any) => {
      s.province = '';
      if (s.lat && s.lng && geoFeatures.length > 0) {
        const pt = turf.point([s.lng, s.lat]);
        for (const f of geoFeatures) {
          if (f.geometry && Object.keys(f.geometry).length > 0) {
            try {
              if (turf.booleanPointInPolygon(pt, f)) {
                s.province = f.properties?.adm1_name1 || f.properties?.adm1_name || '';
                break;
              }
            } catch { /* skip invalid geometry */ }
          }
        }
      }
    });

    _allStations.value = rawStations;
  } catch (e) {
    console.error('Data fetch error:', e);
  } finally {
    mapLoading.value = false;
  }
}

const openStationDetails = (station: any) => {
  selectedStation.value = station;
  drawerVisible.value   = true;
};

const onProvinceSelect = (province: string) => {
  selectedProvince.value = province;
};

onMounted(() => loadData());
</script>

<style scoped>
.station-map {
  height: calc(100vh - 200px);
  transition: height 0.3s ease;
}
.hidden-placeholder { pointer-events: none; }

@media (max-width: 1024px) {
  .station-map.map-visible { height: 700px; }
  .station-map.map-hidden  { height: 200px; }
}
@media (max-width: 640px) {
  .station-map.map-visible { height: 600px; }
}
</style>
