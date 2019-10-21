@Library('libpipelines@master') _

hose {
    EMAIL = 'intelligence'
    PKGMODULESNAMES = ['stratio-toree']
    DEVTIMEOUT = 60
    RELEASETIMEOUT = 60
    NEW_VERSIONING = true
    BUILDTOOL = 'make'
    DEV = { config ->
        doPackage(config)
        doDeploy(config)
    }
}
