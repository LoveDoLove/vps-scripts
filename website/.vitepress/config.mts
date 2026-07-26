import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'en',
  title: 'VPS Scripts',
  description: 'Modular VPS management toolkit with bilingual support',
  base: '/',

  head: [
    ['link', { rel: 'icon', href: '/logo.png' }],
  ],

  locales: {
    root: {
      label: 'English',
      lang: 'en',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/guide/' },
          { text: 'Modules', link: '/modules/' },
          { text: 'GitHub', link: 'https://github.com/LoveDoLove/vps-scripts' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: 'Getting Started',
              items: [
                { text: 'Introduction', link: '/guide/' },
                { text: 'Installation', link: '/guide/installation' },
                { text: 'Usage', link: '/guide/usage' },
                { text: 'Development', link: '/guide/development' },
              ],
            },
          ],
          '/modules/': [
            {
              text: 'Modules',
              items: [
                { text: 'Overview', link: '/modules/' },
                { text: 'System Tools', link: '/modules/system-tools' },
                { text: 'Firewall & WAF', link: '/modules/firewall' },
                { text: 'Kernel & BBR', link: '/modules/kernel-bbr' },
                { text: 'SSL Certificates', link: '/modules/ssl' },
                { text: 'LDNMP Web Stack', link: '/modules/web-ldnmp' },
                { text: 'Docker Management', link: '/modules/docker' },
                { text: 'Docker App Store', link: '/modules/app-store' },
                { text: 'FRP Tunneling', link: '/modules/frp' },
                { text: 'Backup & Cron', link: '/modules/backup' },
                { text: 'Benchmarks', link: '/modules/benchmarks' },
                { text: 'Cloudflare WARP', link: '/modules/warp' },
                { text: 'DD Reinstall', link: '/modules/dd-system' },
                { text: 'Oracle Cloud', link: '/modules/oracle-cloud' },
              ],
            },
          ],
        },
      },
    },
    zh: {
      label: '繁體中文',
      lang: 'zh',
      link: '/zh/',
      themeConfig: {
        nav: [
          { text: '使用指南', link: '/zh/guide/' },
          { text: '功能模組', link: '/zh/modules/' },
          { text: 'GitHub', link: 'https://github.com/LoveDoLove/vps-scripts' },
        ],
        sidebar: {
          '/zh/guide/': [
            {
              text: '快速入門',
              items: [
                { text: '介紹', link: '/zh/guide/' },
                { text: '安裝', link: '/zh/guide/installation' },
                { text: '使用說明', link: '/zh/guide/usage' },
                { text: '開發指南', link: '/zh/guide/development' },
              ],
            },
          ],
          '/zh/modules/': [
            {
              text: '功能模組',
              items: [
                { text: '總覽', link: '/zh/modules/' },
                { text: '系統工具', link: '/zh/modules/system-tools' },
                { text: '防火牆與安全', link: '/zh/modules/firewall' },
                { text: '核心與 BBR', link: '/zh/modules/kernel-bbr' },
                { text: 'SSL 憑證', link: '/zh/modules/ssl' },
                { text: 'LDNMP 網站棧', link: '/zh/modules/web-ldnmp' },
                { text: 'Docker 管理', link: '/zh/modules/docker' },
                { text: 'Docker 應用市場', link: '/zh/modules/app-store' },
                { text: 'FRP 內網穿透', link: '/zh/modules/frp' },
                { text: '備份與排程', link: '/zh/modules/backup' },
                { text: '效能測試', link: '/zh/modules/benchmarks' },
                { text: 'Cloudflare WARP', link: '/zh/modules/warp' },
                { text: 'DD 重裝系統', link: '/zh/modules/dd-system' },
                { text: '甲骨文雲', link: '/zh/modules/oracle-cloud' },
              ],
            },
          ],
        },
      },
    },
  },

  themeConfig: {
    logo: '/logo.png',
    siteTitle: 'VPS Scripts',
    socialLinks: [
      { icon: 'github', link: 'https://github.com/LoveDoLove/vps-scripts' },
    ],
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 LoveDoLove',
    },
  },
})
