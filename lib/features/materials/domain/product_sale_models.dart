import '../../../core/constants/business_ids.dart';

class InputMethodIds {
  const InputMethodIds._();

  static const areaM2 = 'area_m2';
  static const widthLength = 'width_length';
  static const looseQuantity = 'loose_quantity';
  static const boxQuantity = 'box_quantity';
  static const boxPlusLoose = 'box_plus_loose';
  static const ceilingLooseSheets = 'ceiling_loose_sheets';
  static const ceilingBoxQuantity = 'ceiling_box_quantity';
  static const ceilingBoxPlusLoose = 'ceiling_box_plus_loose';
  static const manualPerProduct = 'manual_per_product';
  static const manualQuantity = 'manual_quantity';
  static const serviceOnly = 'service_only';

  static const all = {
    areaM2,
    widthLength,
    looseQuantity,
    boxQuantity,
    boxPlusLoose,
    ceilingLooseSheets,
    ceilingBoxQuantity,
    ceilingBoxPlusLoose,
    manualPerProduct,
    manualQuantity,
    serviceOnly,
  };
}

class ChargeMethodIds {
  const ChargeMethodIds._();

  static const unitOnly = 'unit_only';
  static const boxOnly = 'box_only';
  static const boxPlusLoose = 'box_plus_loose';
  static const areaM2Price = 'area_m2_price';
  static const manualTotal = 'manual_total';
  static const quantityOnly = 'quantity_only';

  static const all = {
    unitOnly,
    boxOnly,
    boxPlusLoose,
    areaM2Price,
    manualTotal,
    quantityOnly,
  };
}

class CustomerAskModeIds {
  const CustomerAskModeIds._();

  static const priceByArea = 'price_by_area';
  static const priceByWidthLength = 'price_by_width_length';
  static const materialsByWidthLength = 'materials_by_width_length';
  static const ceilingSheetsByWidthLength = 'ceiling_sheets_by_width_length';
  static const looseProductSale = 'loose_product_sale';
  static const boxProductSale = 'box_product_sale';
  static const boxPlusLooseSale = 'box_plus_loose_sale';
  static const singleProductManual = 'single_product_manual';
  static const materialsOnly = 'materials_only';

  static const all = {
    priceByArea,
    priceByWidthLength,
    materialsByWidthLength,
    ceilingSheetsByWidthLength,
    looseProductSale,
    boxProductSale,
    boxPlusLooseSale,
    singleProductManual,
    materialsOnly,
  };
}

class BuyModeIds {
  const BuyModeIds._();

  static const areaM2 = InputMethodIds.areaM2;
  static const widthLength = InputMethodIds.widthLength;
  static const looseQuantity = InputMethodIds.looseQuantity;
  static const boxQuantity = InputMethodIds.boxQuantity;
  static const boxPlusLoose = InputMethodIds.boxPlusLoose;
  static const ceilingLooseSheets = InputMethodIds.ceilingLooseSheets;
  static const ceilingBoxQuantity = InputMethodIds.ceilingBoxQuantity;
  static const ceilingBoxPlusLoose = InputMethodIds.ceilingBoxPlusLoose;
  static const manualPerProduct = InputMethodIds.manualPerProduct;
  static const manualQuantity = InputMethodIds.manualQuantity;
  static const serviceOnly = InputMethodIds.serviceOnly;

  static const all = InputMethodIds.all;
}

class InputMethod {
  const InputMethod({
    required this.id,
    required this.nameKhmer,
    required this.descriptionKhmer,
    required this.requiresArea,
    required this.requiresWidthLength,
    required this.requiresLooseQuantity,
    required this.requiresBoxQuantity,
    required this.requiresManualQuantity,
    required this.requiresServiceAmount,
    required this.usesFormula,
    required this.active,
  });

  final String id;
  final String nameKhmer;
  final String descriptionKhmer;
  final bool requiresArea;
  final bool requiresWidthLength;
  final bool requiresLooseQuantity;
  final bool requiresBoxQuantity;
  final bool requiresManualQuantity;
  final bool requiresServiceAmount;
  final bool usesFormula;
  final bool active;
}

typedef BuyMode = InputMethod;

class InputMethodCatalog {
  const InputMethodCatalog._();

  static const defaults = [
    InputMethod(
      id: InputMethodIds.areaM2,
      nameKhmer: 'បញ្ចូលការ៉េ',
      descriptionKhmer: 'បញ្ចូលចំនួនការ៉េ',
      requiresArea: true,
      requiresWidthLength: false,
      requiresLooseQuantity: false,
      requiresBoxQuantity: false,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: true,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.widthLength,
      nameKhmer: 'បញ្ចូលទទឹង × បណ្ដោយ',
      descriptionKhmer: 'គណនាការ៉េពីទទឹងនិងបណ្ដោយ',
      requiresArea: false,
      requiresWidthLength: true,
      requiresLooseQuantity: false,
      requiresBoxQuantity: false,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: true,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.looseQuantity,
      nameKhmer: 'បញ្ចូលចំនួនរាយ',
      descriptionKhmer: 'បញ្ចូលចំនួនរាយ',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: true,
      requiresBoxQuantity: false,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: false,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.boxQuantity,
      nameKhmer: 'បញ្ចូលចំនួនកេស',
      descriptionKhmer: 'បញ្ចូលចំនួនកេស',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: false,
      requiresBoxQuantity: true,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: false,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.boxPlusLoose,
      nameKhmer: 'បញ្ចូលកេស + រាយ',
      descriptionKhmer: 'បញ្ចូលចំនួនកេសនិងចំនួនរាយ',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: true,
      requiresBoxQuantity: true,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: false,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.ceilingLooseSheets,
      nameKhmer: 'ពិដានរាយ',
      descriptionKhmer: 'បញ្ចូលចំនួនពិដានរាយ ហើយប៉ាន់ស្មានការ៉េ',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: true,
      requiresBoxQuantity: false,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: true,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.ceilingBoxQuantity,
      nameKhmer: 'ពិដានជាកេស',
      descriptionKhmer: 'បញ្ចូលចំនួនកេសពិដាន ហើយប៉ាន់ស្មានការ៉េ',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: false,
      requiresBoxQuantity: true,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: true,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.ceilingBoxPlusLoose,
      nameKhmer: 'ពិដានកេស + រាយ',
      descriptionKhmer: 'បញ្ចូលកេសពិដាន និងពិដានរាយ ហើយប៉ាន់ស្មានការ៉េ',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: true,
      requiresBoxQuantity: true,
      requiresManualQuantity: false,
      requiresServiceAmount: false,
      usesFormula: true,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.manualPerProduct,
      nameKhmer: 'បញ្ចូលផ្ទាល់',
      descriptionKhmer: 'បញ្ចូលចំនួនផ្ទាល់តាមផលិតផល',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: false,
      requiresBoxQuantity: false,
      requiresManualQuantity: true,
      requiresServiceAmount: false,
      usesFormula: false,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.manualQuantity,
      nameKhmer: 'បញ្ចូលចំនួនផ្ទាល់',
      descriptionKhmer: 'បញ្ចូលចំនួនសរុបផ្ទាល់',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: false,
      requiresBoxQuantity: false,
      requiresManualQuantity: true,
      requiresServiceAmount: false,
      usesFormula: false,
      active: true,
    ),
    InputMethod(
      id: InputMethodIds.serviceOnly,
      nameKhmer: 'សេវាកម្ម',
      descriptionKhmer: 'បញ្ចូលតម្លៃសេវាកម្ម',
      requiresArea: false,
      requiresWidthLength: false,
      requiresLooseQuantity: false,
      requiresBoxQuantity: false,
      requiresManualQuantity: false,
      requiresServiceAmount: true,
      usesFormula: false,
      active: true,
    ),
  ];

  static InputMethod byId(String id) {
    return defaults.firstWhere(
      (mode) => mode.id == id,
      orElse: () => defaults.first,
    );
  }
}

class BuyModeCatalog {
  const BuyModeCatalog._();

  static const defaults = InputMethodCatalog.defaults;

  static BuyMode byId(String id) => InputMethodCatalog.byId(id);
}

class ChargeMethod {
  const ChargeMethod({
    required this.id,
    required this.nameKhmer,
    required this.descriptionKhmer,
    required this.requiresUnitPrice,
    required this.requiresBoxPrice,
    required this.active,
  });

  final String id;
  final String nameKhmer;
  final String descriptionKhmer;
  final bool requiresUnitPrice;
  final bool requiresBoxPrice;
  final bool active;
}

class ChargeMethodCatalog {
  const ChargeMethodCatalog._();

  static const defaults = [
    ChargeMethod(
      id: ChargeMethodIds.unitOnly,
      nameKhmer: 'គិតតម្លៃរាយ',
      descriptionKhmer: 'គិតតម្លៃតាមចំនួនរាយសរុប',
      requiresUnitPrice: true,
      requiresBoxPrice: false,
      active: true,
    ),
    ChargeMethod(
      id: ChargeMethodIds.boxOnly,
      nameKhmer: 'គិតតម្លៃកេស',
      descriptionKhmer: 'គិតតម្លៃតាមកេស',
      requiresUnitPrice: false,
      requiresBoxPrice: true,
      active: true,
    ),
    ChargeMethod(
      id: ChargeMethodIds.boxPlusLoose,
      nameKhmer: 'គិតកេស + រាយ',
      descriptionKhmer: 'គិតកេសពេញ បូកចំនួនរាយ',
      requiresUnitPrice: true,
      requiresBoxPrice: true,
      active: true,
    ),
    ChargeMethod(
      id: ChargeMethodIds.areaM2Price,
      nameKhmer: 'គិតតម្លៃតាមការ៉េ',
      descriptionKhmer: 'គិតតម្លៃលក់តាមផ្ទៃការ៉េ',
      requiresUnitPrice: false,
      requiresBoxPrice: false,
      active: true,
    ),
    ChargeMethod(
      id: ChargeMethodIds.manualTotal,
      nameKhmer: 'បញ្ចូលតម្លៃសរុបផ្ទាល់',
      descriptionKhmer: 'បញ្ចូលតម្លៃសរុបដោយផ្ទាល់',
      requiresUnitPrice: false,
      requiresBoxPrice: false,
      active: true,
    ),
    ChargeMethod(
      id: ChargeMethodIds.quantityOnly,
      nameKhmer: 'សួរចំនួនសម្ភារៈ',
      descriptionKhmer: 'គណនាចំនួនសម្ភារៈតែប៉ុណ្ណោះ មិនគិតលុយ',
      requiresUnitPrice: false,
      requiresBoxPrice: false,
      active: true,
    ),
  ];

  static ChargeMethod byId(String id) {
    return defaults.firstWhere(
      (mode) => mode.id == id,
      orElse: () => defaults[2],
    );
  }
}

class CustomerAskMode {
  const CustomerAskMode({
    required this.id,
    required this.nameKhmer,
    required this.descriptionKhmer,
    required this.allowedInputMethods,
    required this.allowedChargeMethods,
    required this.requiresOffer,
    required this.requiresProduct,
    required this.isQuantityOnly,
    this.fixedProductId,
  });

  final String id;
  final String nameKhmer;
  final String descriptionKhmer;
  final List<String> allowedInputMethods;
  final List<String> allowedChargeMethods;
  final bool requiresOffer;
  final bool requiresProduct;
  final bool isQuantityOnly;
  final String? fixedProductId;
}

class CustomerAskModeCatalog {
  const CustomerAskModeCatalog._();

  static const ceilingDefaults = [
    CustomerAskMode(
      id: CustomerAskModeIds.priceByArea,
      nameKhmer: 'គិតតម្លៃតាមការ៉េ',
      descriptionKhmer: 'បញ្ចូលការ៉េ ហើយគិតតម្លៃតាមជម្រើសលក់',
      allowedInputMethods: [InputMethodIds.areaM2],
      allowedChargeMethods: [ChargeMethodIds.areaM2Price],
      requiresOffer: true,
      requiresProduct: false,
      isQuantityOnly: false,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.priceByWidthLength,
      nameKhmer: 'គិតតម្លៃតាមទទឹង × បណ្តោយ',
      descriptionKhmer: 'គណនាការ៉េពីទទឹង និងបណ្តោយ ហើយគិតតម្លៃ',
      allowedInputMethods: [InputMethodIds.widthLength],
      allowedChargeMethods: [ChargeMethodIds.areaM2Price],
      requiresOffer: true,
      requiresProduct: false,
      isQuantityOnly: false,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.materialsByWidthLength,
      nameKhmer: 'សួរចំនួនសម្ភារៈតាមទទឹង × បណ្តោយ',
      descriptionKhmer: 'គណនាចំនួនសម្ភារៈពិដានពេញពីទទឹង និងបណ្តោយ',
      allowedInputMethods: [InputMethodIds.widthLength],
      allowedChargeMethods: [ChargeMethodIds.quantityOnly],
      requiresOffer: false,
      requiresProduct: false,
      isQuantityOnly: true,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.ceilingSheetsByWidthLength,
      nameKhmer: 'សួរចំនួនពិដានតាមទទឹង × បណ្តោយ',
      descriptionKhmer: 'គណនាចំនួនសន្លឹកពិដានតែប៉ុណ្ណោះ',
      allowedInputMethods: [InputMethodIds.widthLength],
      allowedChargeMethods: [ChargeMethodIds.quantityOnly],
      requiresOffer: false,
      requiresProduct: false,
      isQuantityOnly: true,
      fixedProductId: 'ceiling_6mm',
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.looseProductSale,
      nameKhmer: 'ទិញផលិតផលរាយ',
      descriptionKhmer: 'បញ្ចូលចំនួនរាយ ហើយគិតតម្លៃរាយ',
      allowedInputMethods: [InputMethodIds.looseQuantity],
      allowedChargeMethods: [ChargeMethodIds.unitOnly],
      requiresOffer: false,
      requiresProduct: true,
      isQuantityOnly: false,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.boxProductSale,
      nameKhmer: 'ទិញជាកេស',
      descriptionKhmer: 'បញ្ចូលចំនួនកេស ហើយគិតតម្លៃកេស',
      allowedInputMethods: [InputMethodIds.boxQuantity],
      allowedChargeMethods: [ChargeMethodIds.boxOnly],
      requiresOffer: false,
      requiresProduct: true,
      isQuantityOnly: false,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.boxPlusLooseSale,
      nameKhmer: 'ទិញកេស + រាយ',
      descriptionKhmer: 'បញ្ចូលចំនួនកេស និងរាយ ហើយគិតទាំងពីរ',
      allowedInputMethods: [InputMethodIds.boxPlusLoose],
      allowedChargeMethods: [ChargeMethodIds.boxPlusLoose],
      requiresOffer: false,
      requiresProduct: true,
      isQuantityOnly: false,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.singleProductManual,
      nameKhmer: 'ទិញផលិតផលមួយមុខ',
      descriptionKhmer: 'ជ្រើសផលិតផលមួយ ហើយបញ្ចូលចំនួនផ្ទាល់',
      allowedInputMethods: [InputMethodIds.manualQuantity],
      allowedChargeMethods: [
        ChargeMethodIds.unitOnly,
        ChargeMethodIds.boxOnly,
        ChargeMethodIds.boxPlusLoose,
      ],
      requiresOffer: false,
      requiresProduct: true,
      isQuantityOnly: false,
    ),
    CustomerAskMode(
      id: CustomerAskModeIds.materialsOnly,
      nameKhmer: 'គណនាសម្ភារៈតែប៉ុណ្ណោះ',
      descriptionKhmer: 'គណនាចំនួនសម្ភារៈពីការ៉េ ឬទទឹង × បណ្តោយ',
      allowedInputMethods: [InputMethodIds.areaM2, InputMethodIds.widthLength],
      allowedChargeMethods: [ChargeMethodIds.quantityOnly],
      requiresOffer: false,
      requiresProduct: false,
      isQuantityOnly: true,
    ),
  ];

  static CustomerAskMode ceilingById(String id) {
    return ceilingDefaults.firstWhere(
      (mode) => mode.id == id,
      orElse: () => ceilingDefaults.first,
    );
  }
}

class DeliveryPayerOption {
  const DeliveryPayerOption({required this.id, required this.nameKhmer});

  final String id;
  final String nameKhmer;
}

class DeliveryPayerCatalog {
  const DeliveryPayerCatalog._();

  static const defaults = [
    DeliveryPayerOption(
      id: DeliveryPayerIds.ownerPays,
      nameKhmer: 'ខ្ញុំជាអ្នកចេញថ្លៃដឹក',
    ),
    DeliveryPayerOption(
      id: DeliveryPayerIds.customerPays,
      nameKhmer: 'អតិថិជនជាអ្នកចេញថ្លៃដឹក',
    ),
    DeliveryPayerOption(
      id: DeliveryPayerIds.noDelivery,
      nameKhmer: 'មិនមានថ្លៃដឹក',
    ),
  ];

  static String label(String id) {
    return defaults
        .firstWhere((option) => option.id == id, orElse: () => defaults.last)
        .nameKhmer;
  }
}

class ProductSaleInput {
  const ProductSaleInput({
    required this.productKindId,
    required this.materialId,
    this.askModeId,
    this.offerId,
    String? inputMethodId,
    String? chargeMethodId,
    String? buyModeId,
    this.areaM2,
    this.widthM,
    this.lengthM,
    this.looseQuantity,
    this.boxQuantity,
    this.manualQuantity,
    this.serviceAmount,
    this.saleUnitPrice,
    this.saleBoxPrice,
    this.salePricePerM2,
    this.includeAreaRevenue = true,
    this.costPricePerM2,
    this.costUnitPrice,
    this.costBoxPrice,
    this.manualTotalPrice,
    this.displaySpec,
    this.useSavedPriceAsDefault = true,
    this.includeDelivery = false,
    this.deliveryModeId = DeliveryModeIds.flatDelivery,
    this.deliveryPayerId = DeliveryPayerIds.noDelivery,
    this.deliveryRate = 0,
    this.allowSaleBelowCost = true,
  }) : inputMethodId =
           inputMethodId ?? buyModeId ?? InputMethodIds.manualQuantity,
       chargeMethodId =
           chargeMethodId ?? buyModeId ?? ChargeMethodIds.boxPlusLoose;

  final String productKindId;
  final String materialId;
  final String? askModeId;
  final String? offerId;
  final String inputMethodId;
  final String chargeMethodId;
  final double? areaM2;
  final double? widthM;
  final double? lengthM;
  final int? looseQuantity;
  final int? boxQuantity;
  final int? manualQuantity;
  final double? serviceAmount;
  final double? saleUnitPrice;
  final double? saleBoxPrice;
  final double? salePricePerM2;
  final bool includeAreaRevenue;
  final double? costPricePerM2;
  final double? costUnitPrice;
  final double? costBoxPrice;
  final double? manualTotalPrice;
  final String? displaySpec;
  final bool useSavedPriceAsDefault;
  final bool includeDelivery;
  final String deliveryModeId;
  final String deliveryPayerId;
  final double deliveryRate;
  final bool allowSaleBelowCost;

  String get buyModeId => inputMethodId;
}

class ProductSaleResult {
  const ProductSaleResult({
    required this.productKindId,
    required this.productKindNameKhmer,
    required this.materialId,
    required this.materialNameKhmer,
    required this.askModeId,
    required this.offerId,
    required this.spec,
    required this.unitKhmer,
    required this.inputMethodId,
    required this.inputMethodNameKhmer,
    required this.chargeMethodId,
    required this.chargeMethodNameKhmer,
    required this.formulaText,
    required this.areaM2,
    required this.widthM,
    required this.lengthM,
    required this.rawQuantity,
    required this.sellQuantity,
    required this.itemsPerBox,
    required this.packagingFullBoxes,
    required this.packagingLooseItems,
    required this.chargedBoxes,
    required this.saleUnitPrice,
    required this.saleBoxPrice,
    required this.salePricePerM2,
    required this.includeAreaRevenue,
    required this.costPricePerM2,
    required this.costUnitPrice,
    required this.costBoxPrice,
    required this.manualTotalPrice,
    required this.productRevenue,
    required this.productCost,
    required this.includeDelivery,
    required this.deliveryModeId,
    required this.deliveryPayerId,
    required this.deliveryRate,
    required this.totalFullBoxes,
    required this.totalLooseItems,
    required this.deliveryFeeTotal,
    required this.deliveryRevenue,
    required this.deliveryCostToOwner,
    required this.customerPayTotal,
    required this.ownerCostTotal,
    required this.ownerProfit,
    required this.costZeroWarning,
    required this.belowCost,
    required this.canAddToTemporarySale,
    required this.validationErrors,
  });

  final String productKindId;
  final String productKindNameKhmer;
  final String materialId;
  final String materialNameKhmer;
  final String? askModeId;
  final String? offerId;
  final String spec;
  final String unitKhmer;
  final String inputMethodId;
  final String inputMethodNameKhmer;
  final String chargeMethodId;
  final String chargeMethodNameKhmer;
  final String formulaText;
  final double? areaM2;
  final double? widthM;
  final double? lengthM;
  final double rawQuantity;
  final int sellQuantity;
  final int itemsPerBox;
  final int packagingFullBoxes;
  final int packagingLooseItems;
  final int chargedBoxes;
  final double saleUnitPrice;
  final double saleBoxPrice;
  final double salePricePerM2;
  final bool includeAreaRevenue;
  final double costPricePerM2;
  final double costUnitPrice;
  final double costBoxPrice;
  final double? manualTotalPrice;
  final double productRevenue;
  final double productCost;
  final bool includeDelivery;
  final String deliveryModeId;
  final String deliveryPayerId;
  final double deliveryRate;
  final int totalFullBoxes;
  final int totalLooseItems;
  final double deliveryFeeTotal;
  final double deliveryRevenue;
  final double deliveryCostToOwner;
  final double customerPayTotal;
  final double ownerCostTotal;
  final double ownerProfit;
  final bool costZeroWarning;
  final bool belowCost;
  final bool canAddToTemporarySale;
  final List<String> validationErrors;

  String get buyModeId => inputMethodId;
  String get buyModeNameKhmer => inputMethodNameKhmer;
  bool get hasErrors => validationErrors.isNotEmpty;
  String get canSellStatusId {
    if (costZeroWarning) {
      return 'unknown_cost';
    }
    if (belowCost) {
      return 'below_cost';
    }
    return 'can_sell';
  }

  String get canSellStatusNameKhmer {
    return switch (canSellStatusId) {
      'unknown_cost' => 'មិនទាន់ដឹងថ្លៃដើម',
      'below_cost' => 'មិនគួរលក់',
      _ => 'អាចលក់បាន',
    };
  }

  ProductSaleResult copyWithDelivery({
    required String deliveryModeId,
    required String deliveryPayerId,
    required double deliveryRate,
    required int totalFullBoxes,
    required int totalLooseItems,
    required double deliveryFeeTotal,
    required double deliveryRevenue,
    required double deliveryCostToOwner,
    required double customerPayTotal,
    required double ownerCostTotal,
    required double ownerProfit,
  }) {
    return ProductSaleResult(
      productKindId: productKindId,
      productKindNameKhmer: productKindNameKhmer,
      materialId: materialId,
      materialNameKhmer: materialNameKhmer,
      askModeId: askModeId,
      offerId: offerId,
      spec: spec,
      unitKhmer: unitKhmer,
      inputMethodId: inputMethodId,
      inputMethodNameKhmer: inputMethodNameKhmer,
      chargeMethodId: chargeMethodId,
      chargeMethodNameKhmer: chargeMethodNameKhmer,
      formulaText: formulaText,
      areaM2: areaM2,
      widthM: widthM,
      lengthM: lengthM,
      rawQuantity: rawQuantity,
      sellQuantity: sellQuantity,
      itemsPerBox: itemsPerBox,
      packagingFullBoxes: packagingFullBoxes,
      packagingLooseItems: packagingLooseItems,
      chargedBoxes: chargedBoxes,
      saleUnitPrice: saleUnitPrice,
      saleBoxPrice: saleBoxPrice,
      salePricePerM2: salePricePerM2,
      includeAreaRevenue: includeAreaRevenue,
      costPricePerM2: costPricePerM2,
      costUnitPrice: costUnitPrice,
      costBoxPrice: costBoxPrice,
      manualTotalPrice: manualTotalPrice,
      productRevenue: productRevenue,
      productCost: productCost,
      includeDelivery: true,
      deliveryModeId: deliveryModeId,
      deliveryPayerId: deliveryPayerId,
      deliveryRate: deliveryRate,
      totalFullBoxes: totalFullBoxes,
      totalLooseItems: totalLooseItems,
      deliveryFeeTotal: deliveryFeeTotal,
      deliveryRevenue: deliveryRevenue,
      deliveryCostToOwner: deliveryCostToOwner,
      customerPayTotal: customerPayTotal,
      ownerCostTotal: ownerCostTotal,
      ownerProfit: ownerProfit,
      costZeroWarning: costZeroWarning,
      belowCost: belowCost,
      canAddToTemporarySale: canAddToTemporarySale,
      validationErrors: validationErrors,
    );
  }
}

class TemporarySaleSummary {
  const TemporarySaleSummary({
    required this.items,
    required this.totalQuantity,
    required this.customerPayTotal,
    required this.ownerCostTotal,
    required this.ownerProfit,
  });

  factory TemporarySaleSummary.fromItems(List<ProductSaleResult> items) {
    return TemporarySaleSummary(
      items: items,
      totalQuantity: items.fold<int>(0, (sum, item) => sum + item.sellQuantity),
      customerPayTotal: items.fold<double>(
        0,
        (sum, item) => sum + item.customerPayTotal,
      ),
      ownerCostTotal: items.fold<double>(
        0,
        (sum, item) => sum + item.ownerCostTotal,
      ),
      ownerProfit: items.fold<double>(0, (sum, item) => sum + item.ownerProfit),
    );
  }

  final List<ProductSaleResult> items;
  final int totalQuantity;
  final double customerPayTotal;
  final double ownerCostTotal;
  final double ownerProfit;
}
