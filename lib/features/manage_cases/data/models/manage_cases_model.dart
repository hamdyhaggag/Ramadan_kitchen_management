class ManageCasesModel {
  List<String> names = [];
  List<bool> checkboxValues = [];
  List<int> serialNumbers = [];
  List<int> numberOfIndividuals = [];

  ManageCasesModel({
    required this.names,
    required this.checkboxValues,
    required this.serialNumbers,
    required this.numberOfIndividuals,
  });

  int calculateTotalIndividuals() =>
      numberOfIndividuals.reduce((value, element) => value + element);

  int calculateTotalCheckedIndividuals() {
    int totalChecked = 0;
    for (int i = 0; i < checkboxValues.length; i++) {
      if (checkboxValues[i]) {
        totalChecked += numberOfIndividuals[i];
      }
    }
    return totalChecked;
  }

  double calculateProgress() {
    final totalIndividuals = calculateTotalIndividuals();
    final totalCheckedIndividuals = calculateTotalCheckedIndividuals();
    return totalIndividuals == 0
        ? 0.0
        : totalCheckedIndividuals / totalIndividuals;
  }
}
