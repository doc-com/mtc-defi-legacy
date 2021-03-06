const G = artifacts.require('G');
const stkMTC = artifacts.require('stkMTC');
const DAOModule = artifacts.require('DAOModule');

module.exports = async (deployer, network) => {
  let multisig;
  if (['mainnet', 'development', 'testing'].includes(network)) {
    multisig = '0x3E7Ff81efBbAdf5FCA2810086b7f4C17a4F3682f';
  }
  else
  if (['rinkeby'].includes(network)) {
    multisig = '0xF074450e1bCB367822f6b9deED2f4784a2a6A5cF';
  }
  else return;
  const vtoken = await stkMTC.deployed();
  deployer.link(G, DAOModule);
  await deployer.deploy(DAOModule, multisig, vtoken.address);
};
