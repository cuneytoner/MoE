import resource


class ResourceLimits:
    """
    Hard limits for unsafe execution
    """

    def apply(self):
        # CPU time limit (seconds)
        resource.setrlimit(resource.RLIMIT_CPU, (2, 2))

        # Max memory ~512MB
        resource.setrlimit(resource.RLIMIT_AS, (512 * 1024 * 1024, 512 * 1024 * 1024))