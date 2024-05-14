# PGENZ NFT-CONTRACT 🔥

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge)
![Forge](https://img.shields.io/badge/Forge-v0.2.0-blue?style=for-the-badge)
[![License: MIT](https://img.shields.io/github/license/trashpirate/pgenz-nft-contract.svg?style=for-the-badge)](https://github.com/trashpirate/pgenz-nft-contract/blob/master/LICENSE)

[![Website: nadinaoates.com](https://img.shields.io/badge/Portfolio-00e0a7?style=for-the-badge&logo=Website)](https://nadinaoates.com)
[![LinkedIn: nadinaoates](https://img.shields.io/badge/LinkedIn-0a66c2?style=for-the-badge&logo=LinkedIn&logoColor=f5f5f5)](https://linkedin.com/in/nadinaoates)
[![Twitter: N0\_crypto](https://img.shields.io/badge/@N0\_crypto-black?style=for-the-badge&logo=X)](https://twitter.com/N0\_crypto)

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#installation">Installation</a></li>
        <li><a href="#usage">Usage</a></li>
      </ul>
    </li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <!-- <li><a href="#acknowledgments">Acknowledgments</a></li> -->
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

![PigeonPark](https://github.com/trashpirate/pgenz-nft-contract/blob/master/title.png?raw=true)

Smart contract inheriting from ERC721A with a native and ERC20 token fee for minting including full deployment/testing suite using Foundry. The NFT contract takes a token and a native token fee, implements whitelists, and allows to extend the collection via sets.

### Smart Contracts Testnet

**Token Contract**  
https://sepolia.etherscan.io/address/0xfda030107eb1de41ae233992c84a6e9c99d3ca34

**NFT Contract**  
https://sepolia.etherscan.io/address/0xd5c933fb3aa049d8f8ebcb60ed2fed40b9c3d9fe

### Smart Contracts Mainnet

**Token Contract**  
https://etherscan.io/token/0x2d17b511a85b401980cc0fed15a8d57fdb8eec60

**NFT Contract**  
https://etherscan.io/address/0x5fa4239c387c6fa089935783176019ae2c112354

<!-- GETTING STARTED -->
## Getting Started

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/trashpirate/pgenz-nft-contract.git
   ```
2. Navigate to the project directory
   ```sh
   cd pgenz-nft-contract
   ```
3. Install Foundry submodules
   ```sh
   forge install
   ```

### Usage

#### Compiling
```sh
forge compile
```

#### Testing locally

Run local tests:  
```sh
forge test
```

Run test with bsc mainnet fork:
1. Start local test environment
    ```sh
    make fork
    ```
2. Run fork tests
    ```sh
    forge test
    ```

#### Deploy to testnet

1. Create test wallet using keystore. Enter private key of test wallet when prompted.
    ```sh
    cast wallet import <KeystoreName> --interactive
    ```
    Update the Makefile accordingly.

2. Deploy to testnet
    ```sh
    make deploy-testnet
    ```

#### Deploy to mainnet
1. Create deployer wallet using keystore. Enter private key of deployer wallet when prompted.
    ```sh
    cast wallet import <KeystoreName> --interactive
    ```
    Update the Makefile accordingly.

2. Deploy to mainnet
    ```sh
    make deploy-mainnet
    ```

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<!-- CONTACT -->
## Contact

Nadina Oates - [@N0_crypto](https://twitter.com/N0_crypto)
Project Link: [https://pgenz-nft.vercel.app](https://pgenz-nft.vercel.app)

<!-- ACKNOWLEDGMENTS -->
<!-- ## Acknowledgments -->

