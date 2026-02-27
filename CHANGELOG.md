## [unreleased]

### 🚀 Features

- *(views)* Add UserLoginView
- *(views)* Add UserRegisterView
- *(views)* Add CandidateListView
- *(views)* Add CandidateEditDetailView
- *(models)* Add generic APIService & Add APIDataModel & Add CandidateBackendService
- *(viewModels)* Add UserRegisterViewModel
- *(views)* Integrate viewModel UserRegisterViewModel to the view UserRegisterView
- *(viewModels)* Add CandidateViewModel
- *(viewModels)* Add CandidateListViewModel
- *(views)* Integrate viewModel CandidateListViewModel to the view CandidateListView
- *(viewModels)* Add CandidateEditDetailViewModel
- *(views)* Integrate viewModel CandidateEditDetailViewModel to the view CandidateDetailView
- *(viewModels)* Add UserLoginViewModel
- *(views)* Integrate viewModels to the view UserLoginView
- *(viewModels)* Add CandidateEditViewModel and update AppViewModel
- *(views)* Add CandidateEditView for delete feature and update navigation for CandidateListView
- *(views)* Add toogle favorite feature from CandidateDetailView
- *(unit-test)* Add xctest for all View Models and for CandidateBackendService
- *(models)* Add KeychainService to secure token access storage
- *(unit-test)* Add xctest for CandidateBackendService with MockKeychain
- *(unit-test)* Add xctest for filteredCandidates

### 🐛 Bug Fixes

- *(utils)* Email with length of domain < 2 is invalid
- *(models)* Remove print commands not for prod
- *(models-views)* Remove unused .environment
- *(views-viewmodels)* Only user with isAdmin true can toogle the isFavorite status

### 💼 Other

- *(models)* Remove debug print in model CandidateBackendService
- *(views-viewmodels)* Enhance views appearance
- *(playground)* Comment all playground to disable it
- *(views-viewmodels)* Move filtered logic in viewModel
- *(models)* Remove the playground
- *(models)* Add async for consistency of actors
- *(project)* Remove unuset swift file

### 📚 Documentation

- *(project)* Add project VitesseRH README.md
- *(viewModels)* Update comment
- *(views)* Update comment
- *(changelog)* Generate CHANGELOG.md with git cliff, thanks to conventional commits
- *(views)* Remove header
- *(changlog)* Update
- *(changlog)* Add git cliff configuration file
- *(changlog)* Update
