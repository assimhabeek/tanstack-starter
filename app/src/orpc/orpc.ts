import { createORPCClient } from '@orpc/client'
import { RPCLink } from '@orpc/client/fetch'
import { createRouterClient, type RouterClient } from '@orpc/server'
import { createTanstackQueryUtils } from '@orpc/tanstack-query'
import { createIsomorphicFn } from '@tanstack/react-start'
import { type Router, router } from './orpc.router'

const getORPCClient = createIsomorphicFn()
  .server((): RouterClient<Router> => createRouterClient(router))
  .client((): RouterClient<Router> => {
    const link = new RPCLink({
      url: `${window.location.origin}/api/rpc`
    })
    return createORPCClient(link)
  })

export const client: RouterClient<Router> = getORPCClient()

export const orpc = createTanstackQueryUtils(client)
