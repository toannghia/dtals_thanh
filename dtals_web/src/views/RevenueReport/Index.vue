<template>
  <div class="revenue-report">
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold text-gray-700">Báo cáo doanh thu</h2>
      <el-button type="success" :loading="exporting" @click="handleExport">
        <el-icon class="mr-1"><Download /></el-icon> Xuất Excel
      </el-button>
    </div>

    <!-- Filters -->
    <div class="lte-card mb-4">
      <div class="lte-card-body flex gap-4 flex-wrap items-end">
        <div class="flex flex-col gap-1">
          <span class="text-xs text-gray-500 ml-1">Khoảng thời gian</span>
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="đến"
            start-placeholder="Từ ngày"
            end-placeholder="Đến ngày"
            :shortcuts="shortcuts"
            @change="handleDateChange"
            format="DD/MM/YYYY"
            value-format="YYYY-MM-DD"
            class="!w-80"
          />
        </div>
        <el-button type="primary" @click="fetchData">Lọc dữ liệu</el-button>
      </div>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
      <div class="lte-card !bg-blue-50 border-blue-100">
        <div class="lte-card-body flex items-center p-6">
          <div class="rounded-full bg-blue-100 p-4 mr-4">
            <el-icon class="text-blue-600 text-2xl"><Money /></el-icon>
          </div>
          <div>
            <p class="text-sm text-blue-600 font-medium uppercase tracking-wider">Tổng doanh thu</p>
            <h3 class="text-3xl font-bold text-blue-900 mt-1">{{ formatCurrency(summary.totalRevenue) }}</h3>
          </div>
        </div>
      </div>
      <div class="lte-card !bg-green-50 border-green-100">
        <div class="lte-card-body flex items-center p-6">
          <div class="rounded-full bg-green-100 p-4 mr-4">
            <el-icon class="text-green-600 text-2xl"><CircleCheck /></el-icon>
          </div>
          <div>
            <p class="text-sm text-green-600 font-medium uppercase tracking-wider">Số đơn thành công</p>
            <h3 class="text-3xl font-bold text-green-900 mt-1">{{ summary.totalOrders }} <span class="text-lg font-normal text-green-700">đơn hàng</span></h3>
          </div>
        </div>
      </div>
    </div>

    <!-- Chart -->
    <div class="lte-card mb-6">
      <div class="lte-card-header">Xu hướng doanh thu</div>
      <div class="lte-card-body">
        <div ref="chartRef" style="width: 100%; height: 350px;"></div>
      </div>
    </div>

    <!-- Details Table -->
    <div class="lte-card">
      <div class="lte-card-header flex justify-between items-center">
        <span>Chi tiết giao dịch doanh thu</span>
        <el-tag type="info" size="small">Tìm thấy: {{ total }}</el-tag>
      </div>
      <div class="lte-card-body">
        <el-table :data="transactions" stripe border v-loading="loading">
          <el-table-column label="STT" width="70" align="center">
            <template #default="{ $index }">
              {{ (page - 1) * limit + $index + 1 }}
            </template>
          </el-table-column>
          <el-table-column label="Khách hàng" min-width="200">
            <template #default="{ row }">
              <div class="flex flex-col">
                <span class="font-medium text-gray-800">{{ row.user?.fullName || 'N/A' }}</span>
                <span class="text-xs text-gray-400">@{{ row.user?.username }}</span>
              </div>
            </template>
          </el-table-column>
          <el-table-column prop="ntripAccountName" label="Tài khoản NTRIP" width="180" />
          <el-table-column prop="packageName" label="Gói dịch vụ" min-width="180" />
          <el-table-column label="Số tiền" width="150" align="right">
            <template #default="{ row }">
              <span class="font-bold text-gray-700">{{ formatCurrency(row.amount) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="Ngày thanh toán" width="180">
            <template #default="{ row }">
              {{ formatDate(row.paidAt) }}
            </template>
          </el-table-column>
        </el-table>
        <div class="mt-4 flex justify-end">
          <el-pagination
            background
            layout="prev, pager, next, total"
            :total="total"
            :page-size="limit"
            v-model:current-page="page"
            @current-change="fetchDetails"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue';
import { ElMessage } from 'element-plus';
import { Download, Money, CircleCheck } from '@element-plus/icons-vue';
import * as echarts from 'echarts';
import { revenueReportApi } from '../../services/api';

const loading = ref(false);
const exporting = ref(false);
const summary = reactive({ totalRevenue: 0, totalOrders: 0 });
const transactions = ref<any[]>([]);
const total = ref(0);
const page = ref(1);
const limit = 10;

// Date range initialization (last 30 days)
const defaultEndDate = new Date();
const defaultStartDate = new Date();
defaultStartDate.setDate(defaultEndDate.getDate() - 29);

const dateRange = ref<[string, string] | null>([
  defaultStartDate.toISOString().split('T')[0] as string,
  defaultEndDate.toISOString().split('T')[0] as string,
]);

const shortcuts = [
  {
    text: '7 ngày qua',
    value: () => {
      const end = new Date();
      const start = new Date();
      start.setDate(start.getDate() - 6);
      return [start, end];
    },
  },
  {
    text: '30 ngày qua',
    value: () => {
      const end = new Date();
      const start = new Date();
      start.setDate(start.getDate() - 29);
      return [start, end];
    },
  },
  {
    text: 'Tháng này',
    value: () => {
      const end = new Date();
      const start = new Date(end.getFullYear(), end.getMonth(), 1);
      return [start, end];
    },
  },
  {
    text: 'Tháng trước',
    value: () => {
      const end = new Date(new Date().getFullYear(), new Date().getMonth(), 0);
      const start = new Date(end.getFullYear(), end.getMonth(), 1);
      return [start, end];
    },
  },
];

// ECharts
const chartRef = ref<HTMLDivElement | null>(null);
let chartInstance: echarts.ECharts | null = null;

const initChart = () => {
  if (chartRef.value) {
    chartInstance = echarts.init(chartRef.value);
  }
};

const updateChart = (data: any[]) => {
  if (!chartInstance) return;

  const dates = data.map((item) => {
    const d = new Date(item.date);
    return `${d.getDate()}/${d.getMonth() + 1}`;
  });
  const revenues = data.map((item) => item.revenue);

  const option = {
    tooltip: {
      trigger: 'axis',
      formatter: (params: any) => {
        const item = params[0];
        return `${item.name}<br/>Doanh thu: <b>${formatCurrency(item.value)}</b>`;
      },
    },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: dates,
      axisLabel: { color: '#666' },
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        formatter: (value: number) => {
          if (value >= 1000000) return (value / 1000000).toFixed(1) + 'M';
          if (value >= 1000) return (value / 1000).toFixed(0) + 'K';
          return value;
        },
        color: '#666',
      },
      splitLine: { lineStyle: { type: 'dashed', color: '#eee' } },
    },
    series: [
      {
        name: 'Doanh thu',
        type: 'line',
        smooth: true,
        data: revenues,
        itemStyle: { color: '#3b82f6' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(59, 130, 246, 0.3)' },
            { offset: 1, color: 'rgba(59, 130, 246, 0)' },
          ]),
        },
        symbolSize: 8,
        emphasis: { focus: 'series' },
      },
    ],
  };

  chartInstance.setOption(option);
};

// Data Fetching
const fetchSummary = async () => {
  if (!dateRange.value) return;
  const [start, end] = dateRange.value;
  try {
    const res = await revenueReportApi.getSummary({
      startDate: start,
      endDate: end,
    });
    summary.totalRevenue = res.data.totalRevenue;
    summary.totalOrders = res.data.totalOrders;
  } catch (e) {
    console.error('Failed to fetch summary', e);
  }
};

const fetchChartData = async () => {
  if (!dateRange.value) return;
  const [start, end] = dateRange.value;
  try {
    const res = await revenueReportApi.getChart({
      startDate: start,
      endDate: end,
    });
    updateChart(res.data);
  } catch (e) {
    console.error('Failed to fetch chart data', e);
  }
};

const fetchDetails = async () => {
  if (!dateRange.value) return;
  const [start, end] = dateRange.value;
  loading.value = true;
  try {
    const res = await revenueReportApi.getDetails({
      startDate: start,
      endDate: end,
      page: page.value,
      limit: limit,
    });
    transactions.value = res.data.items;
    total.value = res.data.total;
  } catch (e) {
    ElMessage.error('Lỗi khi tải danh sách chi tiết');
  } finally {
    loading.value = false;
  }
};

const fetchData = () => {
  page.value = 1;
  fetchSummary();
  fetchChartData();
  fetchDetails();
};

const handleDateChange = () => {
  if (!dateRange.value) {
    dateRange.value = [
      defaultStartDate.toISOString().split('T')[0] as string,
      defaultEndDate.toISOString().split('T')[0] as string,
    ];
  }
  fetchData();
};

const handleExport = async () => {
  if (!dateRange.value) return;
  const [start, end] = dateRange.value;
  exporting.value = true;
  try {
    const res = await revenueReportApi.export({
      startDate: start,
      endDate: end,
    });
    const url = window.URL.createObjectURL(new Blob([res.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `Bao-cao-doanh-thu-${start}-to-${end}.xlsx`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } catch (e) {
    ElMessage.error('Lỗi khi xuất file Excel');
  } finally {
    exporting.value = false;
  }
};

// Utils
const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
};

const formatDate = (dateStr: string) => {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleString('vi-VN');
};

const handleResize = () => {
  chartInstance?.resize();
};

onMounted(() => {
  initChart();
  fetchData();
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  chartInstance?.dispose();
});
</script>

<style scoped>
.lte-card {
  @apply bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden;
}
.lte-card-header {
  @apply px-4 py-3 bg-gray-50 border-b border-gray-100 font-bold text-gray-700;
}
.lte-card-body {
  @apply p-4;
}
</style>
