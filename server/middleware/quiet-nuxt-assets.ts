import { defineEventHandler, sendNoContent } from 'h3'

export default defineEventHandler((event) => {
  if (process.env.NODE_ENV !== 'development') return

  const url = event.node.req.url || ''
  if (url === '/_nuxt/' || url === '/_nuxt') {
    return sendNoContent(event)
  }
})
