<template>
  <div>
    <!-- Split Layout: Map (left) | Stats (right) -->
    <div class="dashboard-split mt-2">
      <!-- LEFT: Map -->
      <div class="dashboard-map" :class="{'map-hidden': !showMap, 'map-visible': showMap}">
        <div class="lte-card h-full relative">
          <div class="lte-card-header flex justify-between items-center z-10 gap-4">
            <div class="flex items-center gap-4">
              <div class="flex items-center gap-2">
                <span class="font-bold text-gray-700">📡 Bản đồ Trạm CORS {{ selectedProvince ? ` - ${selectedProvince}` : '' }}</span>
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

            <!-- Province Filter integrated into header -->
            <el-select
              v-model="selectedProvince"
              placeholder="Lọc theo Tỉnh"
              clearable
              filterable
              class="w-48 !shadow-none"
              size="small"
              @change="handleProvinceChange"
            >
              <el-option label="Tất cả (Việt Nam)" value="" />
              <el-option
                v-for="prov in provinceList"
                :key="prov"
                :label="prov"
                :value="prov"
              />
            </el-select>
          </div>
          <div v-show="showMap" class="lte-card-body !p-0 map-body relative z-0">
            <!-- Loading overlay inside map -->
            <div v-if="mapLoading" class="absolute inset-0 bg-white/50 backdrop-blur-sm z-50 flex items-center justify-center">
              <el-icon class="is-loading text-3xl text-blue-500"><Loading /></el-icon>
            </div>
            <div class="absolute inset-0">
              <MapComponent 
                height="100%" 
                :stations="filteredStations"
                :allStations="_allStations"
                :selectedProvince="selectedProvince"
                :provinceList="provinceList"
                :visible="showMap"
                @province-select="handleProvinceSelect"
              />
            </div>
          </div>
          <!-- Hidden map placeholder -->
          <div v-if="!showMap" class="lte-card-body flex flex-col items-center justify-center min-h-[150px] bg-gray-50 border-t border-gray-100 italic text-gray-400">
            <el-icon :size="30" class="mb-2"><View /></el-icon>
            <p class="text-xs">Bản đồ đang được ẩn. Nhấn icon để hiển thị lại.</p>
          </div>
        </div>
      </div>

      <!-- RIGHT: Stats + Charts -->
      <div class="dashboard-stats">
        <!-- Stat Cards -->
        <div class="grid grid-cols-2 gap-3 mb-4">
          <div class="info-box" v-for="stat in stats" :key="stat.label">
            <div class="info-box-icon" :class="stat.bg">{{ stat.icon }}</div>
            <div class="info-box-content">
              <div class="info-box-text">{{ stat.label }}</div>
              <div class="info-box-number">{{ stat.value }}</div>
            </div>
          </div>
        </div>

        <!-- Station Pie Chart -->
        <div class="lte-card mb-4">
          <div class="lte-card-header">⚡ Tổng quan trạm {{ selectedProvince ? `(${selectedProvince})` : '' }}</div>
          <div class="lte-card-body">
            <div ref="stationChartRef" class="w-full h-[220px]"></div>
          </div>
        </div>

        <!-- User Bar Chart -->
        <div class="lte-card">
          <div class="lte-card-header">📈 Thống kê NTRIP Users</div>
          <div class="lte-card-body">
            <div ref="userChartRef" class="w-full h-[220px]"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import * as echarts from 'echarts';
import { dashboardApi, stationApi, ntripUserApi } from '../../services/api';
import MapComponent from '../../components/MapComponent.vue';
import { Loading, View, Hide } from '@element-plus/icons-vue';
import * as turf from '@turf/turf';

const userChartRef = ref<HTMLElement | null>(null);
const stationChartRef = ref<HTMLElement | null>(null);
const stationCount = ref(0);

// Filter state
const _allStations = ref<any[]>([]);
const provinceList = ref<string[]>([]);
const selectedProvince = ref('');
const mapLoading = ref(true);
// Set default to false if on mobile screen, otherwise true for desktop
const showMap = ref(window.innerWidth > 1024);

const stats = ref([
  { label: 'Tổng trạm', value: '—', icon: '📡', bg: 'bg-blue-500' },
  { label: 'Đang chạy', value: '—', icon: '✅', bg: 'bg-green-500' },
  { label: 'Trạm dừng', value: '—', icon: '🔴', bg: 'bg-red-500' },
  { label: 'NTRIP Users', value: '—', icon: '👥', bg: 'bg-indigo-500' },
]);

let stationChartInstance: echarts.ECharts | null = null;
let userChartInstance: echarts.ECharts | null = null;

const filteredStations = computed(() => {
  if (!selectedProvince.value) return _allStations.value;
  return _allStations.value.filter(s => s.province === selectedProvince.value);
});

async function loadData() {
  mapLoading.value = true;
  try {
    // 1. Fetch Provinces GeoJSON to build dropdown & map stations
    let geoFeatures: any[] = [];
    try {
      const gRes = await fetch('/data/vietnam_provinces.geojson');
      const gData = await gRes.json();
      geoFeatures = gData.features || [];
      const pSet = new Set<string>();
      geoFeatures.forEach(f => {
        const name = f.properties?.adm1_name1 || f.properties?.adm1_name;
        if (name) pSet.add(name);
      });
      provinceList.value = Array.from(pSet).sort();
    } catch {
      console.warn('Could not load geojson for provinces');
    }

    // 2. Fetch map stations
    const res = await stationApi.getStations({ page: 1, size: 9999 });
    const rawStations = res.data?.records || [];
    
    // Assign province to each station using Turf.js point-in-polygon
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
            } catch (err) {
              // turf might throw if invalid geometry
            }
          }
        }
      }
    });

    _allStations.value = rawStations;

    // 3. Fetch Dashboard Stats (Global) - each call independent with retry
    let sd: any = null;
    let ud: any = null;
    
    // Retry helper for intermittent 502 from external CGBAS API
    const retryFetch = async (fn: () => Promise<any>, retries = 3, delay = 1000): Promise<any> => {
      for (let i = 0; i < retries; i++) {
        try {
          return await fn();
        } catch (err: any) {
          const status = err.response?.status;
          if (status === 502 || status === 504 || status === 503) {
            if (i < retries - 1) {
              await new Promise(r => setTimeout(r, delay));
              continue;
            }
          }
          throw err;
        }
      }
    };
    
    // Station stats (with retry)
    try {
      const stationRes = await retryFetch(() => dashboardApi.getStationStats());
      sd = stationRes.data;
    } catch (e: any) {
      console.warn('Station stats API failed after retries:', e.message);
    }
    
    // User stats (with retry + NTRIP fallback)
    try {
      const userRes = await retryFetch(() => dashboardApi.getUserStats());
      ud = userRes.data;
    } catch (e: any) {
      console.warn('User stats API failed, trying NTRIP user list fallback:', e.message);
      try {
        const ntripRes = await retryFetch(() => ntripUserApi.list({ page: 1, size: 1 }));
        const ntripTotal = ntripRes.data?.total ?? ntripRes.data?.records?.length ?? 0;
        ud = { totalUsers: ntripTotal, byStatus: { enabled: ntripTotal, disabled: 0 }, totalOnline: 0 };
      } catch {
        console.warn('NTRIP user fallback also failed');
      }
    }
    
    // Build station stats from API or fallback from raw stations
    if (sd) {
      stationCount.value = sd.total ?? 0;
    } else {
      // Fallback: calculate from raw station data
      const running = rawStations.filter((s: any) => s.status === 1).length;
      const stopped = rawStations.filter((s: any) => s.status !== 1).length;
      sd = {
        total: rawStations.length,
        byStatus: { running, stopped },
        byConnection: { online: 0, noData: 0, offline: 0 }
      };
      stationCount.value = rawStations.length;
    }

    // Build user stats - backend returns { totalUsers, byStatus: { enabled, disabled }, totalOnline }
    if (ud) {
      const userTotal = ud.totalUsers ?? ud.total ?? 0;
      stats.value[3]!.value = String(userTotal);
    } else {
      stats.value[3]!.value = '—';
    }

    // Initial chart render uses global data
    updateStatsAndChart(sd);
    renderUserChart(ud);
    
  } catch (e) {
    console.error('Data fetch error:', e);
  } finally {
    mapLoading.value = false;
  }
}

function updateStatsAndChart(globalData?: any) {
  let running = 0;
  let stopped = 0;
  let online = 0;
  let offline = 0;

  if (selectedProvince.value) {
    // Calculate from filtered array
    running = filteredStations.value.filter(s => s.status === 1).length;
    stopped = filteredStations.value.filter(s => s.status === 0).length;
    online = filteredStations.value.filter(s => s.connectionStatus === 'online').length; 
    if (online === 0 && running > 0) online = running; 
    offline = filteredStations.value.length - online;
  } else if (globalData) {
    running = globalData.byStatus?.running ?? 0;
    stopped = globalData.byStatus?.stopped ?? 0;
    online = globalData.byConnection?.online ?? 0;
    offline = globalData.byConnection?.offline ?? 0;
  } else {
    running = _allStations.value.filter(s => s.status === 1).length;
    stopped = _allStations.value.filter(s => s.status === 0).length;
    online = running;
    offline = stopped;
  }

  const total = running + stopped;
  stats.value[0]!.value = String(total);
  stats.value[1]!.value = String(running);
  stats.value[2]!.value = String(stopped);

  if (stationChartRef.value) {
    if (!stationChartInstance) {
      stationChartInstance = echarts.init(stationChartRef.value);
      window.addEventListener('resize', () => stationChartInstance?.resize());
    }
    stationChartInstance.setOption({
      tooltip: { trigger: 'item' },
      legend: { bottom: '0%', textStyle: { fontSize: 11 } },
      series: [{
        type: 'pie',
        radius: ['35%', '65%'],
        center: ['50%', '45%'],
        label: { show: true, formatter: '{b}: {c}', fontSize: 11 },
        data: [
          { value: running, name: 'Đang chạy', itemStyle: { color: '#22C55E' } },
          { value: stopped, name: 'Dừng', itemStyle: { color: '#EF4444' } },
          { value: online, name: 'Online', itemStyle: { color: '#3B82F6' } },
          { value: offline, name: 'Offline', itemStyle: { color: '#9CA3AF' } },
        ]
      }]
    });
  }
}

function renderUserChart(ud: any) {
  if (!userChartRef.value) return;
  if (!userChartInstance) {
    userChartInstance = echarts.init(userChartRef.value);
    window.addEventListener('resize', () => userChartInstance?.resize());
  }
  
  if (!ud) {
    // No data available, show empty chart
    userChartInstance.setOption({
      tooltip: { trigger: 'axis' },
      grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
      xAxis: { type: 'category', data: ['Tổng', 'Enabled', 'Disabled', 'Online'] },
      yAxis: { type: 'value' },
      series: [{ type: 'bar', data: [0, 0, 0, 0], barWidth: '50%' }]
    });
    return;
  }
  
  // Backend response: { totalUsers, byStatus: { enabled, disabled }, totalOnline }
  const total = ud.totalUsers ?? ud.total ?? 0;
  const enabled = ud.byStatus?.enabled ?? ud.enabled ?? 0;
  const disabled = ud.byStatus?.disabled ?? ud.disabled ?? 0;
  const online = ud.totalOnline ?? ud.online ?? 0;
  
  userChartInstance.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: ['Tổng', 'Enabled', 'Disabled', 'Online'] },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar',
      data: [
        { value: total, itemStyle: { color: '#3B82F6' } },
        { value: enabled, itemStyle: { color: '#22C55E' } },
        { value: disabled, itemStyle: { color: '#EF4444' } },
        { value: online, itemStyle: { color: '#F59E0B' } },
      ],
      barWidth: '50%',
    }]
  });
}

function handleProvinceChange() {
  updateStatsAndChart();
}

function handleProvinceSelect(province: string) {
  selectedProvince.value = province;
  handleProvinceChange();
}

onMounted(() => {
  loadData();
});
</script>

<style scoped>
.dashboard-split {
  display: flex;
  gap: 16px;
  min-height: calc(100vh - 140px);
}
.dashboard-map {
  flex: 1;
  min-width: 0;
}
.dashboard-stats {
  width: 520px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}
.dashboard-map .lte-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}
.dashboard-map .lte-card-body {
  flex: 1;
  min-height: 0;
}

/* Responsive: stack on small screens */
@media (max-width: 1024px) {
  .dashboard-split {
    flex-direction: column;
    min-height: auto;
  }
  .dashboard-stats {
    width: 100%;
  }
  .dashboard-map {
    flex: none;
    margin-bottom: 16px;
    display: flex;
    flex-direction: column;
    transition: height 0.3s ease;
  }
  .dashboard-map.map-visible {
    height: 700px; /* Double height when visible */
  }
  .dashboard-map.map-hidden {
    height: auto; /* Collapse when hidden */
    min-height: 150px;
  }
  .lte-card-header {
    flex-wrap: wrap;
    gap: 8px;
  }
  .lte-card-header > div {
    flex: 1;
    min-width: 200px;
  }
  .lte-card-header .el-select {
    width: 100%;
  }
}

@media (max-width: 640px) {
  .dashboard-map.map-visible {
    height: 600px; /* Double height when visible */
  }
  .info-box-text {
    font-size: 11px;
  }
  .info-box-number {
    font-size: 14px;
  }
}
</style>
