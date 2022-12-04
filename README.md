# OSDU Bicep

This project is used to host Bicep infrastructure that can be used in deploying OSDU on Azure.

## Project Principals

The guiding principal we have with this project is to focus on the the _downstream use_ of the project (see [releases](https://github.com/azure/osdu-bicep/releases)) The goal is to work on infrastructure in a manner that other components can consume infrastructure as code. As such, these are our specific practices.

1. Deploy all components through a single, modular, idempotent bicep template Converge on a single bicep template, which can easily be consumed
2. Provide best-practice defaults, then use parameters for flagging on additional options.
3. Minimize "manual" steps for ease of automation
4. Maintain quality through validation & CI/CD pipelines

## Modules

Below is a table containing all published modules. Each version badge shows the latest version of the corresponding module.

<!-- Begin Module Table -->

| Module                         |                                                                                                                                                           Version |                                                                                                                                                                                                                              Docs |
| :----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| `public/app-configuration`     |     <a href="https://github.com/azure/osdu-bicep/releases/tag/public/app-configuration/1.0.2"><image src="https://img.shields.io/badge/osdubicep-1.0.2-blue"></a> |         [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/app-configuration/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/app-configuration/README.md) |
| `public/azure-keyvault`        |        <a href="https://github.com/azure/osdu-bicep/releases/tag/public/azure-keyvault/1.0.3"><image src="https://img.shields.io/badge/osdubicep-1.0.3-blue"></a> |               [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/azure-keyvault/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/azure-keyvault/README.md) |
| `public/container-registry`    |    <a href="https://github.com/azure/osdu-bicep/releases/tag/public/container-registry/1.0.2"><image src="https://img.shields.io/badge/osdubicep-1.0.2-blue"></a> |       [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/container-registry/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/container-registry/README.md) |
| `public/cosmos-db`             |           <a href="https://github.com/azure/osdu-bicep/releases/tag/public/cosmos-db/1.0.15"><image src="https://img.shields.io/badge/osdubicep-1.0.15-blue"></a> |                         [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/cosmos-db/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/cosmos-db/README.md) |
| `public/log-analytics`         |         <a href="https://github.com/azure/osdu-bicep/releases/tag/public/log-analytics/1.0.4"><image src="https://img.shields.io/badge/osdubicep-1.0.4-blue"></a> |                 [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/log-analytics/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/log-analytics/README.md) |
| `public/private-endpoint`      |      <a href="https://github.com/azure/osdu-bicep/releases/tag/public/private-endpoint/1.0.1"><image src="https://img.shields.io/badge/osdubicep-1.0.1-blue"></a> |           [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/private-endpoint/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/private-endpoint/README.md) |
| `public/storage-account`       |       <a href="https://github.com/azure/osdu-bicep/releases/tag/public/storage-account/1.0.5"><image src="https://img.shields.io/badge/osdubicep-1.0.5-blue"></a> |             [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/storage-account/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/storage-account/README.md) |
| `public/user-managed-identity` | <a href="https://github.com/azure/osdu-bicep/releases/tag/public/user-managed-identity/1.0.2"><image src="https://img.shields.io/badge/osdubicep-1.0.2-blue"></a> | [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/user-managed-identity/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/user-managed-identity/README.md) |
| `public/virtual-network`       |       <a href="https://github.com/azure/osdu-bicep/releases/tag/public/virtual-network/1.0.5"><image src="https://img.shields.io/badge/osdubicep-1.0.5-blue"></a> |             [🦾 Code](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/virtual-network/main.bicep) ｜ [📃 Readme](https://github.com/azure/osdu-bicep/blob/main/bicep/modules/public/virtual-network/README.md) |

<!-- End Module Table -->

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
