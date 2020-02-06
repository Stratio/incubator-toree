@Library('libpipelines@master') _

hose {
    EMAIL = 'intelligence'
    MODULE = 'stratio-intelligence-toree'
    REPOSITORY = 'incubator-toree'
    PKGMODULESNAMES = ['stratio-toree']
    DEVTIMEOUT = 60
    RELEASETIMEOUT = 60
    ANCHORE_TEST = true
    DEPLOYONPRS = true
    NEW_VERSIONING = true
    BUILDTOOL = 'make'
    DEV = { config ->
        doPackage(config)
        doDeploy(config)
    }
}
